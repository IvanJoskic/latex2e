#!/usr/bin/env texlua

-- Build script for LaTeX2e "base" files

-- Identify the bundle and module
module = "base"
bundle = ""

-- CTAN's name for this is a bit different from ours
ctanpkg = "latex-base"

-- Location of main directory: use Unix-style path separators
maindir = ".."

docfiledir = "./doc"

-- Set up the file types needed here
docfiles = {"ltnews??.tex"}
installfiles   =
  {
    "*.cfg",
    "*.clo",
    "*.cls",
    "*.def",
    "*.dfu",
    "*.fd",
    "*.ltx",
    "*.lua",
    "*.sty",
    "docstrip.tex",
    "idx.tex",
    "lablst.tex",
    "lppl.tex",
    "ltluatex.tex",
    "ltxcheck.tex",
    "nfssfont.tex",
    "sample2e.tex",
    "small2e.tex",
    "testpage.tex",
  }
sourcefiles    =
  {
    "ltnews.cls",
    "ltxguide.cls",
    "minimal.cls",
    "*.dtx",
    "*.fdd",
    "*.ins",
    "idx.tex",
    "lablst.tex",
    "ltxcheck.tex",
    "sample2e.tex",
    "small2e.tex",
    "testpage.tex",
  }
textfiles =
  {
    "README.md",
    "bugs.txt",
    "legal.txt",
    "manifest.txt",
    "changes.old.txt",
    "changes.txt",
    "lppl.txt",
    "lppl-1-0.txt",
    "lppl-1-1.txt",
    "lppl-1-2.txt",
    "tex2.txt",
    "texpert.txt"
  }
typesetfiles   =
  {
    "source2e.tex", -- Has to be first: source2e.ist creation!
    "alltt.dtx",
    "classes.dtx",
    "cmfonts.dtx",
    "doc.dtx",
    "docstrip.dtx",
    "exscale.dtx",
    "fix-cm.dtx",
    "graphpap.dtx",
    "ifthen.dtx",
    "inputenc.dtx",
    "ltunicode.dtx",
    "utf8ienc.dtx",
    "latexrelease.dtx",
    "latexsym.dtx",
    "letter.dtx",
    "ltluatex.dtx",
    "ltxdoc.dtx",
    "makeindx.dtx",
    "nfssfont.dtx",
    "proc.dtx",
    "slides.dtx",
    "slifonts.dtx",
    "syntonly.dtx",
    "*.fdd",
    "*.err",
    "lppl.tex",
    "cfgguide.tex",
    "clsguide.tex",
    "cyrguide.tex",
    "encguide.tex",
    "fntguide.tex",
    "ltnews.tex",
    "ltx3info.tex",
    "modguide.tex",
    "usrguide.tex",
    "latexchanges.tex"
  }
dynamicfiles = {"*.tst"}

-- A few special file for unpacking
unpackfiles     = {"unpack.ins"}
unpacksuppfiles =
  {
    "EastAsianWidth.txt",
    "hyphen.cfg",
    "LineBreak.txt",
    "load-unicode-data.tex",
    "load-unicode-xetex-classes.tex",
    "MathClass.txt",
    "UnicodeData.txt",
    "UShyphen.tex",
    "ot1lmr.fd",
    "pdflatex.ini",
    "pdftexconfig.tex"
  }

-- Custom settings for the check system
testsuppdir = "testfiles/helpers"

-- No dependencies at all (other than l3build of course)
checkdeps   = { }
typesetdeps = { }
unpackdeps  = { }

-- Customise typesetting
indexstyle = "source2e.ist"

-- Allow for TU test
checkconfigs = {"build","config-TU"}

-- Detail how to set the version automatically
function update_tag(file,content,tagname,tagdate)
  local year = os.date("%Y")
  if string.match(content,"%% Copyright %d%d%d%d%-%d%d%d%d") then
    content = string.gsub(content,
      "Copyright (%d%d%d%d)%-%d%d%d%d",
      "Copyright %1-" .. year)
  elseif string.match(content,"%% Copyright %d%d%d%d\n") then
    local oldyear = string.match(content,"%% Copyright (%d%d%d%d)\n")
    if not year == oldyear then
      content = string.gsub(content,
        "Copyright %d%d%d%d",
        "Copyright " .. oldyear .. "-" .. year)
    end
  end
  if not string.match(file,"%.md$") or not string.match(file,"ltvers.dtx") then
    -- Stop here for files other than .md
    return content
  end
  local iso = "%d%d%d%d%-%d%d%-%d%d"
  local tag, rev = string.match(tagname,"^(.*):([^:]*)$")
  local patch_level = ""
  if master_branch then
    if rev then
      tag = tag .. " patch level " .. rev
      patch_level = rev
    end
  else
    tag = tag .. " pre-release "
    if rev then
      tag = tag .. rev
      patch_level = "-" .. rev
    end
  end
  if file == "README.md" then
    return string.gsub(content,
      "\nRelease " .. iso .. "[^\n]*\n",
      "\nRelease " .. tag .. "\n")
  elseif file == "ltvers.dtx" then
    return string.gsub(content,
      "\\patch@level{%-?%d+}",
      "\\patch@level{" .. patch_level .. "}")
  end
  return content
end

function format ()
  local errorlevel = unpack ()
  if errorlevel ~=0 then
    return errorlevel
  end
  local function format (engine,fmtname)
    -- the relationships are all correct
    local sourcefile = unpackdir .. "/latex.ltx"
    local finalname = string.gsub(engine,"tex","latex")
    if fileexists(localdir .. "/" .. finalname .. ".ini") then
       sourcefile = localdir .. "/" .. finalname .. ".ini"
    end
    local errorlevel = os.execute (
        os_setenv .. " TEXINPUTS=" .. unpackdir .. os_pathsep .. localdir
        .. os_concat ..
        engine .. " -etex -ini " .. " -output-directory=" .. unpackdir ..
        " -jobname=latex " .. sourcefile
      )
    if errorlevel ~=0 then
      return errorlevel
    end
    ren (unpackdir, "latex.fmt", fmtname)
    -- As format building is added in as an 'extra', the normal
    -- copy mechanism (checkfiles) will fail as things get cleaned up
    -- inside bundleunpack(): get around that using a manual copy
    cp (fmtname, unpackdir, localdir)
    if fmtname == "elatex.fmt" then
      rm(localdir, "latex.fmt")
      ren(localdir, fmtname, "latex.fmt")
    end
    return 0
  end
  if not options["config"] or options["config"][1] ~= "config-TU" then
    cp("fonttext.cfg",supportdir,unpackdir)
  end
  local fmtengines = options["engine"] or checkengines
  if not options["config"] then
    table.insert(fmtengines,"pdftex")
  end
  for _,i in ipairs(fmtengines) do
    errorlevel = format (i, string.gsub (i, "tex$", "") .. "latex.fmt")
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  return 0
end

-- Custom bundleunpack which does not search the localdir
-- That is needed as texsys.cfg is unpacked in an odd way and
-- without this will otherwise not be available
function bundleunpack ()
  local errorlevel = mkdir(localdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  errorlevel = cleandir(unpackdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  for _,i in ipairs (sourcefiles) do
    errorlevel = cp (i, ".", unpackdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  for _,i in ipairs (unpacksuppfiles) do
    errorlevel = cp (i, supportdir, localdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  for _,i in ipairs (unpackfiles) do
    for _,j in ipairs (filelist (unpackdir, i)) do
      os.execute (os_yes .. ">>" .. localdir .. "/yes")
      errorlevel = os.execute (
          -- Notice that os.execute is used from 'here' as this ensures that
          -- localdir points to the correct place: running 'inside'
          -- unpackdir would avoid the need for setting -output-directory
          -- but at the cost of needing to correct the relative position
          -- of localdir w.r.t. unpackdir
          os_setenv .. " TEXINPUTS=" .. unpackdir .. os_concat ..
          unpackexe .. " " .. unpackopts .. " -output-directory=" .. unpackdir
            .. " " .. unpackdir .. "/" .. j .. " < " .. localdir .. "/yes"
        )
      if errorlevel ~=0 then
        return errorlevel
      end
    end
  end
  return 0
end

-- base does all of the targets itself
function main (target, file, engine)
  local errorlevel
  if target == "check" then
    if not options["rerun"] then
      format()
    end
    errorlevel = check (file, engine)
  elseif target == "clean" then
    errorlevel = clean ()
  elseif target == "ctan" then
    format ()
    errorlevel = ctan (true)
  elseif target == "doc" then
    errorlevel = doc ()
  elseif target == "install" then
    install ()
  elseif target == "save" then
    if file then
      errorlevel = save (file, engine)
    else
      help ()
    end
  elseif target == "tag" then
    errorlevel = tag(file,engine)
  elseif target == "unpack" then
    -- A simple way to have the unpack target also build the format
    errorlevel = format ()
  elseif target == "uninstall" then
    errorlevel = uninstall()
  elseif target == "version" then
    version ()
  else
    help ()
  end
  os.exit (errorlevel)
end

-- Load the common settings for the LaTeX2e repo
dofile (maindir .. "/build-config.lua")

-- Find and run the build system
kpse.set_program_name ("kpsewhich")
if not release_date then
  dofile(kpse.lookup("l3build.lua"))
end

