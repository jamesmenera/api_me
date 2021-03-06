module ApiMe
  module Generators
    class ControllerGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      check_class_collision suffix: 'Controller'

      argument :attributes, type: :array, default: [], banner: 'field field'

      class_option :parent, type: :string, desc: 'The parent class for the generated controller'

      def create_api_controller_file
        template 'controller.rb', File.join('app/controllers',
                                            controllers_namespace,
                                            controllers_api_version,
                                            "#{plural_name}_controller.rb")
        insert_after_version(plural_name)
      end

      def controllers_namespace
        'api'
        # @generators.options.fetch(:api, {}).fetch(:namespace, 'api')
      end

      def controllers_api_version
        'v1'
        # @generators.options.fetch(:api, {}).fetch(:version, 'v1')
      end

      def controller_class_name
        "#{controllers_namespace.capitalize}::"\
        "#{controllers_api_version.capitalize}::"\
        "#{plural_name.camelize}Controller"
      end

      def attributes_names
        [:id] + attributes.reject(&:reference?).map { |a| a.name.to_sym }
      end

      def associations
        attributes.select(&:reference?)
      end

      def nonpolymorphic_attribute_names
        associations.select { |attr| attr.type.in?(%i[belongs_to references]) }
                    .reject { |attr| attr.attr_options.fetch(:polymorphic, false) }
                    .map { |attr| "#{attr.name}_id".to_sym }
      end

      def polymorphic_attribute_names
        associations.select { |attr| attr.type.in?(%i[belongs_to references]) }
                    .select { |attr| attr.attr_options.fetch(:polymorphic, false) }
                    .map { |attr| ["#{attr.name}_id".to_sym, "#{attr.name}_type".to_sym] }.flatten
      end

      def association_attribute_names
        nonpolymorphic_attribute_names + polymorphic_attribute_names
      end

      def strong_parameters
        (attributes_names + association_attribute_names).map(&:inspect).join(', ')
      end

      def parent_class_name
        if options[:parent]
          options[:parent]
        else
          'ApplicationController'
        end
      end

      private

      def insert_after_version(resource_name)
        maybe_create_api_v1_namespace

        in_root do
          insert_into_file(
            'config/routes.rb',
            "      resources :#{resource_name}\n",
            after: "namespace :#{controllers_api_version} do\n"
          )
        end
      end

      def maybe_create_api_v1_namespace
        in_root do
          unless File.readlines('config/routes.rb').grep("namespace #{controllers_namespace} do")
            route <<-ROUTE
namespace :#{controllers_namespace} do
    namespace :#{controllers_api_version} do
    end
  end
ROUTE
          end
        end
      end
    end
  end
end
