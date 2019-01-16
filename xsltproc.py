#!/usr/bin/python 

import os
import cgi, cgitb, urllib

cgitb.enable()
form=cgi.FieldStorage()



xml = '/Library/Webserver/Documents/register/forms/20090607-155731.xml'
xsl = '/Library/Webserver/Documents/register/styles/viewform.xsl'


def transform(xml,xsl=''):
    return os.popen("xsltproc %s %s" % (xsl, xml)).read()

print 'Content-type: text/html'
print
print transform(xml, xsl)
