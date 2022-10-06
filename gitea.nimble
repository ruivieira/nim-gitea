# Package

version       = "0.1.0"
author        = "Rui Vieira"
description   = "Project Description"
license       = "Apache-2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["gitea"]


# Dependencies

requires "nim >= 1.6.6"
requires "jsony"

task docs, "Generate project docs":
    exec "nim doc --project --index:on  --outdir:docs src/gitea.nim"