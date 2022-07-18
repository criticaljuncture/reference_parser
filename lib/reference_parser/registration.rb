module ReferenceParser::Registration
  def self.included(base)
    base.extend SetupMethods
  end

  module SetupMethods
    def replacements
      @replacements
    end

    def replace(...)
      @replacements ||= []
      @replacements << ReferenceParser::Replacement.new(...)
    end
  end

  def replacements
    @replacements ||= (self.class.replacements.dup || []).map do |replacement|
      replacement.parser = self
      replacement
    end
  end
end
