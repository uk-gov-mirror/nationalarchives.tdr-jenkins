package uk.gov.nationalarchives.pluginupdates

import com.github.tomakehurst.wiremock.WireMockServer
import com.github.tomakehurst.wiremock.client.WireMock.{get, ok, okJson, urlEqualTo}
import com.github.tomakehurst.wiremock.stubbing.StubMapping
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers
import org.scalatest.{BeforeAndAfterAll, BeforeAndAfterEach}
import scala.sys.process._

import scala.io.Source.fromResource

class PluginUpdateSpec extends AnyFlatSpec with Matchers with BeforeAndAfterEach with BeforeAndAfterAll {
  val wiremockGithubServer = new WireMockServer(9001)
  val wiremockJenkinsServer = new WireMockServer(9002)

  override def beforeAll(): Unit = {
    wiremockGithubServer.start()
    wiremockJenkinsServer.start()
  }

  override def beforeEach(): Unit = {
    wiremockJenkinsServer.resetAll()
    wiremockGithubServer.resetAll()
  }

  override def afterEach(): Unit = {
    "rm -f plugins.txt pr-notes".!!
  }

  override def afterAll(): Unit = {
    wiremockGithubServer.stop()
    wiremockJenkinsServer.stop()
  }

  def jenkinsWithoutWarnings: StubMapping = wiremockJenkinsServer.stubFor(get(urlEqualTo("/"))
    .willReturn(okJson(fromResource(s"json/jenkins-plugins-without-warnings.json").mkString)))

  def jenkinsWithWarnings: StubMapping = wiremockJenkinsServer.stubFor(get(urlEqualTo("/"))
    .willReturn(okJson(fromResource(s"json/jenkins-plugins-with-warnings.json").mkString)))

  def githubResponse: StubMapping = wiremockGithubServer.stubFor(get(urlEqualTo("/"))
    .willReturn(ok("plugin1:1.0.0\nplugin2:1.0.0")))

}
