import sbt._

object Dependencies {
  lazy val catsEffect = "org.typelevel" %% "cats-effect" % "2.2.0"
  lazy val sttp = "com.softwaremill.sttp.client3" %% "async-http-client-backend-cats" % "3.1.3"
  lazy val sttpCirce = "com.softwaremill.sttp.client3" %% "circe" % "3.1.3"
  lazy val scalaTest = "org.scalatest" %% "scalatest" % "3.2.2"
  lazy val typesafeConfig = "com.typesafe" % "config" % "1.4.1"
  lazy val wiremock = "com.github.tomakehurst" % "wiremock" % "2.27.2"
}

