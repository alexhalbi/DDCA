from collections import OrderedDict
import binascii

class TestSuite:

    DATA_WIDTH = 32
    ADDR_WIDTH = 21


    def __init__(self, filename, **kwargs):
        self.fd = open(filename, "w")
        self.sig = OrderedDict()
        self.total_width = 0

        self.rec_fd = None
        if "record" in kwargs and kwargs["record"] is not None:
            self.rec_fd = open(kwargs["record"], "w")

            self.rec_fd.write("#!/usr/bin/python\n")
            self.rec_fd.write("from test import TestSuite\n")
            self.rec_fd.write("suite = TestSuite(\"%s\")\n" % filename)

    def __del__(self):
        self.fd.close()

    @staticmethod
    def dec2bin(dec, l):
        if dec < 0:
            return bin(dec & 2**l-1)
        else:
            return str("{:0"+str(l)+"b}").format(dec)

    @staticmethod
    def conv(arg, l):
        if isinstance(arg, basestring):
            val = arg
            if arg.startswith("0x"):
                num = int(arg, 16)
                val = TestSuite.dec2bin(num, l)
                return val
            if len(val) is not l:
                raise Exception("Wrong signal length %i (%s)" % (len(val), val))
            val = arg.replace("-", "-")
            return val

        if isinstance(arg, (int, long)):
            return TestSuite.dec2bin(arg, l)

        if isinstance(arg, bool):
            if l is not 1:
                raise "Booleans need a length of 1"
            if arg:
                return "1"
            else:
                return "0"

        if arg is None:
            return TestSuite.dec2bin(0, l)

    def put(self, arg, name, l):
        self.fd.write(TestSuite.conv(arg, l))

    def printSignalAssignments(self):
        tmp = self.total_width

        for list_name, signature in self.sig.iteritems():
            name = signature['signal_name']
            l = signature['length']
            if l is 1:
                print("%s <= vec(%i);" % (name, tmp-1))
                tmp -= 1
            else:
                a = tmp-1
                b = tmp-1-l
                print("%s <= vec(%i downto %i);" % (name, a, b+1))
                tmp -= l

    def addSignal(self, signal_name, length, **kwargs):

        name = None
        if "alias" in kwargs:
            name = kwargs["alias"]
        else:
            name = signal_name

        if name in self.sig:
            raise "Signal %s already added" % name

        default = kwargs["default"]

        signature = dict()
        signature['length'] = length
        signature['signal_name'] = signal_name
        signature['default'] = default

        self.sig[name] = signature
        self.total_width += length



        if self.rec_fd:
            if isinstance(default, basestring):
                self.rec_fd.write('suite.addSignal("%s", %i, alias="%s", default="%s")\n' 
                    % (signal_name, length, kwargs["alias"], default))
            else:
                self.rec_fd.write('suite.addSignal("%s", %i, alias="%s", default=%s)\n' 
                    % (signal_name, length, kwargs["alias"], default))


    def test(self, nr, **kwargs):

        for name, signature in self.sig.iteritems():
            if name in kwargs:
                self.put(kwargs[name], signature['signal_name'], signature['length'])
            else:
                if signature['default'] is None:
                    raise "No default value set for %s" % name
                self.put(signature['default'], signature['signal_name'], signature['length'])
        self.fd.write("\n")
        if self.rec_fd:
            args = ""
            i=0
            l=len(kwargs)
            for key, value in kwargs.iteritems():
                i+=1
                if isinstance(value, basestring):
                    args += "%s=\"%s\"" % (key, value)
                else:
                    args += "%s=%s" % (key, value)
                if i is not l:
                    args += ", "
            self.rec_fd.write('suite.test(%i, %s)\n' % (int(nr), args))
