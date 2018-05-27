import os, osproc
import hashes, strutils

# Inspect command line parameters
let args =  commandLineParams()

if args.len == 0:
  stderr.write "Usage: nimcr filename [compile target, default 'c' [options]]"
  quit -1

let
  filename = args[0].expandFilename

# Split the file path and make a new one which is a hidden file on Linux, Windows file hiding comes later
let
  splitName = filename.splitfile
  ext =
    when defined(windows):
      ".exe"
    else:
      ""
  exeName = splitName.dir/("." & splitName.name & ext)

# Compilation of script if target doesn't exist
var
  buildStatus = 0
  output = ""
  command = ""

var argsExe = ""
if args.len > 1:
  argsExe = join(args[1..(args.len- 1)], " ")

if not exeName.existsFile or filename.fileNewer exeName:
  # Get any extra arguments from the command and compile
  let extraArgs = "c"

  exeName.removeFile
  command = "nim " & extraArgs & " --colors:on --nimcache:" &
    getTempDir()/("nimcache-" & filename.hash.toHex) &
    " -d:release --out:\"" & exeName & "\" " & filename

  (output, buildStatus) = execCmdEx(command)
  # Windows file hiding (hopefully, not tested)
  when defined(windows):
    execShellCmd("attrib +H " & exeName)

# Run the target, or show an error
if buildStatus == 0:
  quit execShellCmd(exeName & " " & argsExe)
else:
  stderr.write "(nimcr) Error on build running command: " & command
  stderr.write output
  quit buildStatus
