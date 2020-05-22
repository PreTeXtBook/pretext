#!/usr/bin/env python3
# ********************************************************************
# Copyright 2010-2020 Robert A. Beezer
#
# This file is part of PreTeXt.
#
# PreTeXt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# PreTeXt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
# *********************************************************************

# 2020-05-20: this script expects Python 3.4 or newer

# This is an extremely simple demonstration of how to
# employ the pretext module in a Python application

# Import the module into the local namespace as "ptx"
import pretext as ptx

# Read arguments from the command line with the standard "sys" module
import sys # argv

import os.path # abspath()

# module is parameterized by the level of console output
# Not necessary, default is 0 and no output
# Maximum level set here
ptx.set_verbosity(2)

# directory/file locations provided on command-line by user
# routines in module expect complete absolute paths
xml_source = os.path.abspath(sys.argv[1])
dest_dir = os.path.abspath(sys.argv[2])

# we do one minimal task as the demonstration
# each <latex-image> in the source will give rise to a TeX file (only)
# various options are not employed
# function signature is
#
# latex_image_conversion(xml_source, stringparams, root_xmlid, data_dir, dest_dir, 'source')
#
ptx.latex_image_conversion(xml_source, None, '', None, dest_dir, 'source')

