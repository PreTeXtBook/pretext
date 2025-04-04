#!/bin/bash

# When journals.xml is updated, run this script from the journals directory to create a pretext table in the guide's appendices folder which "journals.xml" will import.

# Build the journals-table for the documentation
xsltproc journals-to-table.xsl journals.xml > ../doc/guide/appendices/journals-table.xml