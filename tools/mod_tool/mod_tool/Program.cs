using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace mod_tool
{
    class Program
    {
        const double PAL = 7093789.2;
        const double FREQ = 255.0 * 50.0;           // 71 is probably the smallest size (VGA takes a timing hit)
        public static FileBuffer buffer;
        static void Main(string[] args)
        {
            buffer = new FileBuffer(8192);
            for(var i = 0; i<4096; i++)
            {
                if (i == 0)
                {
                    buffer.Write16((UInt16)0x4000);
                }
                else
                {
                    // work out note freq
                    double d = PAL / (((double)i) * 2);
                    // Now resample it as well...
                    d = d / FREQ;

                    d = d * 256.0;
                    if(d >= 65536.0)
                    {                        
                        d = 0xffff;
                    }

                    buffer.Write16((UInt16)d);
                }
            }
            buffer.Save(@"C:\source\ZXSpectrum\mod_player\code\note_table.dat");


            // create a one over table....
            buffer = new FileBuffer(64*256);
            for (int i = 0; i < 64; i++)
            {
                double volume = i;
                int index = i << 8;
                for (int b = -128; b < 128; b++)
                {
                    double vol = volume / 63.0;
                    double result = b * vol;
                    byte v;
                    int offset = 0;
                    unchecked
                    {
                        v = ((byte)result);
                        offset = (byte)b;
                    }

                    buffer.Write8(index+offset, (byte) v );
                }
            }
            buffer.Save(@"C:\source\ZXSpectrum\mod_player\code\mod_volume.dat");
        }
    }
}
