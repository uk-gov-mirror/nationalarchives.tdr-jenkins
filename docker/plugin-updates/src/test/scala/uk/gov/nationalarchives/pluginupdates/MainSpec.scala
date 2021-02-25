package uk.gov.nationalarchives.pluginupdates

import scala.io.Source
import scala.sys.process._

class MainSpec extends PluginUpdateSpec {

  "The run method" should "produce the correct notes if there are no security warnings" in {
    jenkinsWithoutWarnings
    githubResponse
    Main.run(List()).unsafeRunSync()
    val notesSource = Source.fromFile("pr-notes")
    val lines = notesSource.getLines().filter(_.nonEmpty).toList
    lines.length should equal(1)
    lines.head.trim should equal("Plugin plugin2 will be updated from version 1.0.0 to version 1.0.1")
  }

  "The run method" should "produce the correct notes if there are security warnings" in {
    wiremockGithubServer.start()
    wiremockJenkinsServer.start()
    jenkinsWithWarnings
    githubResponse
    Main.run(List()).unsafeRunSync()
    val notesSource = Source.fromFile("pr-notes")
    val lines = notesSource.getLines().map(_.trim).mkString("\n")
    lines should equal(
      """
        |Plugin plugin1 will be updated from version 1.0.0 to version 1.0.1
        |The following security warnings have been issued:
        |Some warning
        |
        |
        |Plugin plugin2 will be updated from version 1.0.0 to version 1.0.2""".stripMargin)
    "rm plugins.txt pr-notes".!
  }

  "The run method" should "update the plugins file with the correct values" in {
    jenkinsWithWarnings
    githubResponse
    Main.run(List()).unsafeRunSync()
    val pluginsSource = Source.fromFile("plugins.txt")
    pluginsSource.getLines().mkString(",") should equal("plugin1:1.0.1,plugin2:1.0.2")
  }
}
