-- docbook.lua - Class that provides functions for working with docbook documents.
-- Copyright (C) 2015 Pavel Vomacka
--
-- This program is free software:  you can redistribute it and/or modify it
-- under the terms of  the  GNU General Public License  as published by the
-- Free Software Foundation, version 3 of the License.
--
-- This program  is  distributed  in the hope  that it will be useful,  but
-- WITHOUT  ANY WARRANTY;  without  even the implied warranty of MERCHANTA-
-- BILITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
-- License for more details.
--
-- You should have received a copy of the GNU General Public License  along
-- with this program. If not, see <http://www.gnu.org/licenses/>.


-- Define the class:
docbook = {}
docbook.__index = docbook


--
--- Function that has to be call the first. It sets all variables. 
--  If test is run from root directory of book, path variable will be empty string.
--
--  @param language of this document. For example: en-US
--  @param path to the directory where this book has publican.cfg file. Optional parameter, if not set then path will be set to "".
function docbook.create(language, path)
  if language == nil then
    fail("Language of document has to be set. e.g. 'en-US'")
    return nil
  end
  
  -- Set default value of docbook object.
  local docb = {["conf_file_name"]="publican.cfg"}
  
  if path == nil then 
    path = ""
  end
    
  -- Set object attributes.
  setmetatable(docb, docbook)
  
  docb.path = path
  docb.language = language
  
  -- Return the new object. 
  return docb
end


--
--- Function that checks whether all attributes are set.
--
--  @return true when everything is set. Otherwise returns false.
function docbook:checkAttributes()
  if self.path == nil or self.language == nil then
    -- Both or one of the attributes is not set. Print error message.
    fail("Attributes error, path:" .. self.path .. ", language:" .. self.language .. ".")
    return false
  end
  
  -- Everything is OK, return true.
  return true
end


--
--- Function that checks whether directory is the root directory of docbook document.
--
--  @return true when everything is correct. Otherwise false.
function docbook:isDocbook()
  -- Path and language variables has to be set.
  if not self:checkAttributes() then
    return nil
  end
  
  -- Check whether publican.cfg exist.
  if not path.file_exists(self.conf_file_name) then
    fail("File " .. self.conf_file_name .. " does not exists.")
    return false
  end
  
  return true
end


--
--- Function that finds the file where the document starts.
--
--  @return path to the file 
function docbook:findStartFile()  
  -- Lists the files in language directory.
  local command = "ls " .. path.compose(self.path, self.language .. "/*.ent")
  
  -- Execute command and return the output and substitute .xml suffix for .ent.
  return string.gsub(execCaptureOutputAsString(command), "%.ent$", ".xml", 1)
end


--
--- Function that finds document type. Type can be Book or Article and returns it.
--
--  @return 'Book' or 'Article' string according to type of book.
function docbook:getDocumentType()
  if not self:checkAttributes() then
    return nil
  end
  
  -- Get if there si Book_Info.xml or Article_Info.xml
  local command = "cat " .. path.compose(self.path, self.conf_file_name) .. " | grep -E '^[ \t]*type:[ \t]*.*' | awk '{ print $2 }' | sed 's/[[:space:]]//g'"
   
  -- Book or Article, execute command and return its output.
  local output = execCaptureOutputAsString(command)  
  
  -- In case that type is not mentioned in publican.cfg
  if output == "" then
    output = "Book"
  end
  
  return output
end


--
--- Function that finds document title and returns it.
--
--  @return document title as string.
function docbook:getDocumentTitle()
  if not self:checkAttributes() then
    return nil
  end
  
  require "xml"
  local document_type = self:getDocumentType()
  
  
  local xmlObj = xml.create(path.compose(self.language, document_type .. "_Info.xml"))
  return xmlObj:getFirstElement("title")
end


--
--- Function that finds product name and returns it.
--
--  @return  product name as string.
function docbook:getProductName()
  if not self:checkAttributes() then
    return nil
  end
  
  require "xml"
  local document_type = self:getDocumentType()
  
  local xmlObj = xml.create(path.compose(self.language, document_type .. "_Info.xml"))
  return xmlObj:getFirstElement("productname")
end


--
--- Function that finds product version and returns it.
--
--  @return product version as string.
function docbook:getProductVersion()
  if not self:checkAttributes() then
    return nil
  end
  
  require "xml"
  local document_type = self:getDocumentType()
  
  local xmlObj = xml.create(path.compose(self.language, document_type .. "_Info.xml"))
  return xmlObj:getFirstElement("productnumber")
end


--
--- Function that removes all punctuation characters from both sides of string.
--  It also removes all spaces from both sides of the string, too.
--
-- @param text string which should be edited
-- @return edited string
function docbook.trimString(text)
  if string.len(text) > 2 then
    local getOutput = text:gmatch("[%p%s]*(%w[%w%s%p]*%w)[%p%s]*$")
    return getOutput()
  else
    local getOutput = text:gmatch("[%p%s]*(%w*)[%p%s]*$")
    return getOutput()
  end
end


--
--- Function that parse values from publican.cfg file.
--
--  @param item_name is name of value which we want to find. The name without colon.
--  @return the value.
function docbook:getPublicanOption(item_name)
  local command = "cat " .. path.compose(self.path, self.conf_file_name) .. " | grep -E '^[ \t]*" .. item_name .. ":[ \t]*.*' | sed 's/^[^:]*://'"
   
  -- Execute command, trim output and return it.
  return self.trimString(execCaptureOutputAsString(command))
end
