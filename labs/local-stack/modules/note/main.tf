variable "filename" {
  type        = string
  description = "Path the root module wants this note written to."
}

variable "body" {
  type        = string
  description = "Note contents. The caller builds this string."
}

resource "local_file" "this" {
  filename = var.filename
  content  = "${var.body}\n"
}

output "filename" {
  value = local_file.this.filename
}
