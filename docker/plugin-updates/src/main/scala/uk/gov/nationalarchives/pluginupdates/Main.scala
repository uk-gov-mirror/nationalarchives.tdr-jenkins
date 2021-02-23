package uk.gov.nationalarchives.pluginupdates

import java.io.{File, FileOutputStream}
import java.nio.charset.Charset

import cats.effect._
import io.circe.{Decoder, HCursor, Json}
import sttp.client3._
import sttp.client3.asynchttpclient.cats.AsyncHttpClientCatsBackend
import sttp.client3.circe._

object Main extends IOApp {
  implicit val cs: ContextShift[IO] = IO.contextShift(scala.concurrent.ExecutionContext.global)

  case class PluginUpdates(pluginName: String, oldVersion: String, newVersion: String, warning: List[PluginWarning])

  case class Plugin(name: String, version: String)

  def getCurrentPlugins(): IO[List[Plugin]] = {
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"https://raw.githubusercontent.com/nationalarchives/tdr-jenkins/master/docker/plugins.txt"))
        extractedBody <- IO.fromEither(response.body.left.map(err => new Exception(err)))
      } yield extractedBody.split("\n").toList.map(line => {
        val splitLine = line.split(":")
        Plugin(splitLine.head, splitLine.last)
      })
    }
  }

  case class PluginVersions(pattern: String)

  case class PluginWarning(message: String, name: String, versionPatterns: List[PluginVersions])

  case class JenkinsPlugins(warnings: List[PluginWarning])

  implicit val decodePluginVersion: Decoder[PluginVersions] = (c: HCursor) => for {
    pattern <- c.downField("pattern").as[String]
  } yield {
    PluginVersions(pattern)
  }

  implicit val decodePluginWarning: Decoder[PluginWarning] = (c: HCursor) => for {
    message <- c.downField("message").as[String]
    name <- c.downField("name").as[String]
    versions <- c.downField("versions").as[List[PluginVersions]]
  } yield {
    PluginWarning(message, name, versions)
  }

  implicit val decodePlugins: Decoder[JenkinsPlugins] = (c: HCursor) => for {
    warnings <- c.downField("warnings").as[List[PluginWarning]]
  } yield {
    JenkinsPlugins(warnings)
  }


  def getPluginWarnings(currentPluginNames: List[String]): IO[List[PluginWarning]] = {
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"https://updates.jenkins.io/current/update-center.actual.json").response(asJson[JenkinsPlugins]))
        extractedBody <- IO.fromEither(response.body.left.map(err => new Exception(err)))
      } yield extractedBody.warnings.filter(w => currentPluginNames.contains(w.name))
    }
  }

  def getLatestPluginVersions(existingPlugins: List[String]): IO[List[Plugin]] = {
    AsyncHttpClientCatsBackend.resource[IO]().use { backend =>
      for {
        response <- backend.send(basicRequest.get(uri"https://updates.jenkins.io/current/update-center.actual.json").response(asJson[Json]))
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
    val newPluginsTxt = pluginUpdates.map(pu => s"${pu.pluginName}:${pu.newVersion}").mkString("\n")
    Resource.fromAutoCloseable(IO(new FileOutputStream(new File("docker/plugins.txt")))).use(outputStream => {
      outputStream.write(s"$newPluginsTxt\n".getBytes(Charset.defaultCharset()))
      IO(outputStream)
    })
  }

  def prNotes(pluginUpdates: List[PluginUpdates]): IO[FileOutputStream] = {
    val notes = pluginUpdates.filter(pu => pu.newVersion > pu.oldVersion).map(plugin => {
      val warningString = plugin.warning
        .map(_.message).toSet.mkString("\n")
      val warningMessage = if (!warningString.isEmpty) {
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