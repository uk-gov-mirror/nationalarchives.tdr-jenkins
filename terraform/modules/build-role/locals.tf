locals {
  name = "TDRJenkinsBuild${replace(title(var.name), "-", "")}"
}
