# Copyright (c) 2010 Thiago Arrais
#
# This file is part of rODF.
#
# rODF is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.

# rODF is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with rODF.  If not, see <http://www.gnu.org/licenses/>.

require 'erb'

module ODF
  class Skeleton
    def manifest(document_type)
      ERB.new(template('manifest.xml.erb')).result(binding)
    end

    def styles
      template('styles.xml')
    end
  private
    def template(fname)
      File.open(File.dirname(__FILE__) + '/skeleton/' + fname).read
    end
  end
end
