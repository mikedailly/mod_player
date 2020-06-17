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
        const double FREQ = 104.0 * 50.0;
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

                    buffer.Write16((UInt16)d);
                }
            }

            buffer.Save(@"C:\source\ZXSpectrum\mod_player\code\note_table.dat");
        }
    }
}
