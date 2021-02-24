package uk.gov.nationalarchives.pluginupdates

import com.github.tomakehurst.wiremock.WireMockServer
import com.github.tomakehurst.wiremock.client.WireMock._
import com.github.tomakehurst.wiremock.stubbing.StubMapping
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

import scala.io.Source
import scala.io.Source.fromResource
import scala.sys.process._

class MainSpec extends AnyFlatSpec with Matchers {
  val wiremockGithubServer = new WireMockServer(9001)
  val wiremockJenkinsServer = new WireMockServer(9002)

  def jenkinsWithoutWarnings: StubMapping = wiremockJenkinsServer.stubFor(get(urlEqualTo("/"))
    .willReturn(okJson(fromResource(s"json/jenkins-plugins-without-warnings.json").mkString)))

  def jenkinsWithWarnings: StubMapping = wiremockJenkinsServer.stubFor(get(urlEqualTo("/"))
    .willReturn(okJson(fromResource(s"json/jenkins-plugins-with-warnings.json").mkString)))

  def githubResponse: StubMapping = wiremockGithubServer.stubFor(get(urlEqualTo("/"))
    .willReturn(ok("plugin1:1.0.0\nplugin2:1.0.0")))

  "The run method" should "produce the correct notes if there are no security warnings" in {
    wiremockGithubServer.start()
    wiremockJenkinsServer.start()
    jenkinsWithoutWarnings
    githubResponse
    Main.run(List()).unsafeRunSync()
    val notesSource = Source.fromFile("pr-notes")
    val lines = notesSource.getLines().filter(_.nonEmpty).toList
    lines.length should equal(1)
    lines.head.trim should equal("Plugin plugin2 will be updated from version 1.0.0 to version 1.0.1")
    "rm plugins.txt pr-notes".!
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
    wiremockGithubServer.start()
    wiremockJenkinsServer.start()
    jenkinsWithWarnings
    githubResponse
    Main.run(List()).unsafeRunSync()
    val pluginsSource = Source.fromFile("plugins.txt")
    pluginsSource.getLines().mkString(",") should equal("plugin1:1.0.1,plugin2:1.0.2")
    "rm plugins.txt pr-notes".!
  }
}
