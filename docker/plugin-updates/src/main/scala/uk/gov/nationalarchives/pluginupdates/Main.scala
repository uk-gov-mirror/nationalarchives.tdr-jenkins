package uk.gov.nationalarchives.pluginupdates

import cats.effect._

object Main extends IOApp {
   def run(args: List[String]): IO[ExitCode] =
    IO(println(s"Hello")).as(ExitCode.Success)    
}