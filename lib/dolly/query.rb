require "dolly/connection"
require "dolly/collection"
require "dolly/representations/document_representation"
require "dolly/representations/collection_representation"
require "dolly/name_space"
require "exceptions/dolly"

module Dolly
  module Query
    module ClassMethods
      include Dolly::NameSpace
      include Dolly::Connection
      attr_accessor :properties

      DESIGN_DOC = "dolly"

      def find *ids
        response = default_view(keys: ids.map{ |id| [name_paramitized, base_id(id)] }).parsed_response
        ids.count > 1 ? Collection.new(response, name.constantize) : self.new.from_json(response)
      rescue NoMethodError => err
        if err.message == "undefined method `[]' for nil:NilClass"
          raise Dolly::ResourceNotFound
        else
          raise
        end
      end

      def all
        q = {startkey: [name_paramitized,nil], endkey: [name_paramitized,{}]}
        Collection.new default_view(q).parsed_response, name.constantize
      end

      def default_view options = {}
        view default_doc, options
      end

      def view doc, options = {}
        options.merge! include_docs: true
        database.get doc, options
      end

      def timestamps!
        %i/created_at updated_at/.each do |method|
          define_method(method){ @doc[method.to_s] ||= DateTime.now }
          define_method(:"[]"){|m| self.send(m.to_sym) }
          define_method(:"[]="){|m, v| self.send(:"#{m}=", v) }
          define_method(:"#{method}="){|val| @doc[method.to_s] = val }
        end
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end