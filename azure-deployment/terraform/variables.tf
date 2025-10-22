variable "project"   { type = string }
variable "env"       { type = string }
variable "location"  { type = string   default = "eastus" }
variable "image_tag" { type = string   default = "local" }
variable "tags"      { type = map(string) default = {} }
