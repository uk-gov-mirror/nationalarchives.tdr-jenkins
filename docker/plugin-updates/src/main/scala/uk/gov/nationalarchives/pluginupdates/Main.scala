package uk.gov.nationalarchives.pluginupdates

import java.io.{File, FileOutputStream}
import java.nio.charset.Charset
import cats.effect._
import com.typesafe.config.ConfigFactory
import io.circe.{Decoder, HCursor, Json}
import sttp.client3._
import sttp.client3.asynchttpclient.cats.AsyncHttpClientCatsBackend
import sttp.client3.circe._
import uk.gov.nationalarchives.pluginupdates.Decoders._

object Main extends IOApp {
  implicit val cs: ContextShift[IO] = IO.contextShift(scala.concurrent.ExecutionContext.global)
  private val config = ConfigFactory.load()

  def getCurrentPlugins(): IO[List[Plugin]] = {
    val url = config.getString("urls.github.plugins")
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"$url"))
        extractedBody <- IO.fromEither(response.body.left.map(err => new Exception(err)))
      } yield extractedBody.split("\n").toList.map(line => {
        val splitLine = line.split(":")
        Plugin(splitLine.head, splitLine.last)
      })
    }
  }

  def getPluginWarnings(currentPluginNames: List[String]): IO[List[PluginWarning]] = {
    val url = config.getString("urls.jenkins.plugins")
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"$url").response(asJson[JenkinsPlugins]))
        extractedBody <- IO.fromEither(response.body.left.map(err => new Exception(err)))
      } yield extractedBody.warnings.filter(w => currentPluginNames.contains(w.name))
    }
  }

  def getLatestPluginVersions(existingPlugins: List[String]): IO[List[Plugin]] = {
    val url = config.getString("urls.jenkins.plugins")
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"$url").response(asJson[Json]))
        extractedBody <- IO.fromEither(response.body.left.map(err => new Exception(err)))
      } yield {
        val keys = extractedBody.hcursor.downField("plugins").keys.getOrElse(List())
        keys.flatMap(key => {
          extractedBody.hcursor.downField("plugins").downField(key).get[String]("version").toOption.map(version => Plugin(key, version))
        }).filter(plugin => existingPlugins.contains(plugin.name)).toList
      }
    }
  }

  def getPluginUpdates(plugins: List[Plugin], warnings: List[PluginWarning], latestVersions: List[Plugin]): List[PluginUpdates] = {
    def doesVersionMatch(plugin: Plugin, warning: PluginWarning): Boolean =
      warning.versionPatterns.map(_.pattern).exists(pattern => plugin.version.matches(pattern))

    plugins.flatMap(plugin => {
      val filteredWarnings = warnings.filter(warning => warning.name == plugin.name && doesVersionMatch(plugin, warning))
      val latestVersion = latestVersions.find(lv => lv.name == plugin.name)
      latestVersion.map(lv => PluginUpdates(plugin.name, plugin.version, lv.version, filteredWarnings))
    })
  }

  def writePluginUpdates(pluginUpdates: List[PluginUpdates]) = {
    val config = ConfigFactory.load()
    val newPluginsTxt = pluginUpdates.map(pu => s"${pu.pluginName}:${pu.newVersion}").mkString("\n")
    Resource.fromAutoCloseable(IO(new FileOutputStream(new File(config.getString("paths.plugins"))))).use(outputStream => {
      outputStream.write(s"$newPluginsTxt\n".getBytes(Charset.defaultCharset()))
      IO(outputStream)
    })
  }

  def prNotes(pluginUpdates: List[PluginUpdates]): IO[FileOutputStream] = {
    val notes = pluginUpdates.filter(pu => pu.newVersion > pu.oldVersion).map(plugin => {
      val warningString = plugin.warning
        .map(_.message).toSet.mkString("\n")
      val warningMessage = if (warningString.nonEmpty) {
        s"""
           |The following security warnings have been issued:
           |$warningString
           |""".stripMargin
      } else {
        ""
      }
      s"\nPlugin ${plugin.pluginName} will be updated from version ${plugin.oldVersion} to version ${plugin.newVersion} $warningMessage"
    }).mkString("\n")
    val file = new File("pr-notes")
    file.createNewFile()
    Resource.fromAutoCloseable(IO(new FileOutputStream(file))).use(outputStream => {
      outputStream.write(notes.getBytes(Charset.defaultCharset()))
      IO(outputStream)
    })
  }

  def run(args: List[String]): IO[ExitCode] = for {
    currentPlugins <- getCurrentPlugins()
    currentPluginNames = currentPlugins.map(_.name)
    latestVersions <- getLatestPluginVersions(currentPluginNames)
    warnings <- getPluginWarnings(currentPluginNames)
    pluginUpdates <- IO(getPluginUpdates(currentPlugins, warnings, latestVersions))
    _ <- prNotes(pluginUpdates)
    _ <- writePluginUpdates(pluginUpdates)
  } yield ExitCode.Success
}