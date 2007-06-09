#
# xmlscan/encoding.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: encoding.rb,v 1.3 2003/01/12 04:10:33 katsu Exp $
#

require 'xmlscan/visitor'


module XMLScan

  class EncodingError < Error ; end


  class Converter

    def initialize
    end

    def convert(s)
      s
    end

    def finish
      ''
    end

  end



  class SimpleConverter < Converter

    def SimpleConverter.new_class(block)
      Class.new(self).module_eval {
        define_method(:convert, block)
        self
      }
    end

    # checking for Module#define_method works
    begin
      Class.new.module_eval{define_method(:a){};self}.new.a
    rescue Exception
      class << SimpleConverter
        remove_method :new_class
      end
      def SimpleConverter.new_class(block)
        Class.new(self).module_eval {
          const_set :ConvProc, block
          module_eval "def convert(s) ; ConvProc.call s ; end"
          self
        }
      end
    end

  end



  class EncodingClass

    KCODE_None = //n.kcode


    class ConverterProperty

      def inspect
        "#<Conversion #{@from.name}:#{@to.name} #{@cost}>"
      end

      def initialize(from, to, cost, klass = nil)
        @from, @to, @cost, @klass = from, to, cost, klass
      end

      def new_converter
        @klass and @klass.new
      end

      attr_reader :from, :to, :cost

    end


    class EncodingProperty

      def inspect
        s = "#<Encoding #{@name}/#{@kcode}>"
      end

      def initialize(name)
        @name = name
        conv = ConverterProperty.new(self, self, 0)
        @converter = { self => conv }
        @convertable_from = { self => true }
        @kcode_map = {}
      end

      attr_reader :name, :kcode_map


      def convertable_from(encoding)
        @convertable_from[encoding] = true
      end
      protected :convertable_from

      def changed
        @convertable_from.each_key { |i| i.update_kcode_map }
      end
      private :changed


      def kcode?
        defined? @kcode
      end

      def kcode
        if defined? @kcode then
          @kcode
        else
          KCODE_None
        end
      end

      def kcode=(kcode)
        if defined? @kcode then
          raise EncodingError, "KCODE conflict" unless @kcode == kcode
        else
          @kcode = kcode
          changed
        end
        kcode
      end


      def converter(to)
        @converter[to]
      end

      def add_converter(to, cost, conv_class)
        if equal? to then
          raise EncodingError,"attempt to add a converter to the same encoding"
        end
        oldconv = @converter[to]
        if not oldconv or cost <= oldconv.cost then
          conv = ConverterProperty.new(self, to, cost, conv_class)
          @converter[to] = conv
          to.convertable_from self
          changed
        end
        nil
      end


      def update_kcode_map
        @kcode_map.clear
        @converter.each_value { |conv|
          k = conv.to.kcode
          if conv.to.kcode? and k then
            oldconv = @kcode_map[k]
            @kcode_map[k] = conv if not oldconv or conv.cost <= oldconv.cost
          end
        }
      end
      protected :update_kcode_map

    end



    def initialize
      @encoding = {}
    end

    class << self
      private :new
      attr_reader :instance
    end
    @instance = new


    private

    def get_encoding(name)
      encoding = @encoding[name.downcase]
      raise EncodingError, "undeclared encoding `#{name}'" unless encoding
      encoding
    end

    def touch_encoding(name)
      name = name.downcase
      encoding = @encoding[name]
      encoding = @encoding[name] = EncodingProperty.new(name) unless encoding
      encoding
    end


    public

    def alias(newname, oldname)
      newname = newname.downcase
      if @encoding.key? newname then
        raise EncodingError, "encoding `#{newname}' is already declared"
      end
      @encoding[newname] = get_encoding(oldname)
      nil
    end


    def kcode(name)
      encoding = @encoding[name.downcase]
      if encoding then
        encoding.kcode
      else
        KCODE_None
      end
    end


    def set_kcode(name, kcode)
      if kcode then
        kcode = Regexp.new('', nil, kcode).kcode
      else
        kcode = nil
      end
      touch_encoding(name).kcode = kcode
    end


    def add_converter(from, to, cost, conv_class = nil, &block)
      if block and conv_class then
        raise ArgumentError, "multiple converters given"
      elsif not block and not conv_class then
        raise ArgumentError, "no converter given"
      else
        block = conv_class if Proc === conv_class
        conv_class = SimpleConverter.new_class(block) if block
      end
      from = touch_encoding(from)
      to = touch_encoding(to)
      from.add_converter to, cost, conv_class
    end


    def converter(from, to)
      fromenc = get_encoding(from)
      toenc = get_encoding(to)
      conv = fromenc.converter(toenc)
      raise EncodingError, "can't convert `#{from}' to `#{to}'" unless conv
      conv.new_converter
    end


    def converter3(from, to = nil)
      to = from unless to
      fromenc = get_encoding(from)
      toenc = get_encoding(to)
      kcode_map = fromenc.kcode_map
      if kcode_map.empty? then
        if fromenc.kcode and fromenc.equal? toenc then
          return [ nil, fromenc.kcode, nil ]
        else
          raise EncodingError, "can't convert `#{from}' to any KCODE"
        end
      end
      mincost, minkcode, minconv = nil
      kcode_map.each { |kcode,conv|
        conv2 = conv.to.converter(toenc)
        if conv2 then
          cost = conv.cost + conv2.cost
          if not mincost or cost < mincost then
            mincost, minkcode, minconv = cost, kcode, conv
          end
        end
      }
      unless mincost then
        raise EncodingError, "can't convert `#{from}' to `#{to}' via any KCODE"
      end
      conv = minconv.new_converter
      conv2 = minconv.to.converter(toenc)
      conv2 = conv2 && conv2.new_converter
      [ conv, minkcode, conv2 ]
    end

  end


  Encoding = EncodingClass.instance

  Encoding.set_kcode 'utf-8', 'U'
  Encoding.set_kcode 'utf-16', nil
  Encoding.alias 'iso-10646-ucs-2', 'utf-16'
  Encoding.set_kcode 'iso-10646-ucs-4', nil
  Encoding.set_kcode 'iso-8859-1', 'N'
  Encoding.set_kcode 'iso-8859-2', 'N'
  Encoding.set_kcode 'iso-8859-3', 'N'
  Encoding.set_kcode 'iso-8859-4', 'N'
  Encoding.set_kcode 'iso-8859-5', 'N'
  Encoding.set_kcode 'iso-8859-6', 'N'
  Encoding.set_kcode 'iso-8859-7', 'N'
  Encoding.set_kcode 'iso-8859-8', 'N'
  Encoding.set_kcode 'iso-8859-9', 'N'
  Encoding.set_kcode 'iso-2022-jp', nil
  Encoding.set_kcode 'shift_jis', 'S'
  Encoding.set_kcode 'Windows-31J', 'S'
  Encoding.set_kcode 'euc-jp', 'E'
  Encoding.set_kcode 'euc-kr', 'E'

end
