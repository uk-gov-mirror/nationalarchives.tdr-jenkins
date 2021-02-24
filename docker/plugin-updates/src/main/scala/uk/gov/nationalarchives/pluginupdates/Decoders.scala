package uk.gov.nationalarchives.pluginupdates

import io.circe.{Decoder, HCursor}

object Decoders {

  case class PluginUpdates(pluginName: String, oldVersion: String, newVersion: String, warning: List[PluginWarning])

  case class Plugin(name: String, version: String)

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
}
