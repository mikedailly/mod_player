using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace mod_tool
{
    public class FileBuffer
    {
        /// <summary>The file buffer</summary>
        public byte[] buffer;
        /// <summary>current file index</summary>
        public int index;

        public FileBuffer(int _size)
        {
            buffer = new byte[_size];
            index = 0;
        }

        /// <summary>
        ///     Save the buffer
        /// </summary>
        /// <param name="_filename"></param>
        public void Save(string _filename)
        {
            System.IO.File.WriteAllBytes(_filename, buffer);
        }

        public void Seek(int _index)
        {
            index = _index;
        }

        #region Write 8
        public void Write8(byte _val)
        {
            buffer[index] = _val;
            index++;
        }
        public void Write8(int _index, byte _val)
        {
            buffer[_index] = _val;
        }
        #endregion

        #region Write 16
        public void Write16(UInt16 _val)
        {
            buffer[index] = (byte)(_val & 0xff);
            buffer[index + 1] = (byte)((_val >> 8) & 0xff);
            index += 2;
        }
        public void Write16(int _index, UInt16 _val)
        {
            buffer[_index] = (byte)(_val & 0xff);
            buffer[_index + 1] = (byte)((_val >> 8) & 0xff);
        }
        #endregion

        #region Write 24
        public void Write24(Int32 _val)
        {
            buffer[index] = (byte)(_val & 0xff);
            buffer[index + 1] = (byte)((_val >> 8) & 0xff);
            buffer[index + 2] = (byte)((_val >> 16) & 0xff);
            index += 3;
        }
        public void Write24(int _index, Int32 _val)
        {
            buffer[_index] = (byte)(_val & 0xff);
            buffer[_index + 1] = (byte)((_val >> 8) & 0xff);
            buffer[_index + 2] = (byte)((_val >> 16) & 0xff);
        }
        #endregion

        #region Write 32
        public void Write32(UInt32 _val)
        {
            buffer[index] = (byte)(_val & 0xff);
            buffer[index + 1] = (byte)((_val >> 8) & 0xff);
            buffer[index + 2] = (byte)((_val >> 16) & 0xff);
            buffer[index + 3] = (byte)((_val >> 24) & 0xff);
            index += 4;
        }
        public void Write32(int _index, UInt32 _val)
        {
            buffer[_index] = (byte)(_val & 0xff);
            buffer[_index + 1] = (byte)((_val >> 8) & 0xff);
            buffer[_index + 2] = (byte)((_val >> 16) & 0xff);
            buffer[_index + 3] = (byte)((_val >> 24) & 0xff);
        }


        public void Write32(Int32 _val)
        {
            UInt32 v = unchecked((UInt32)_val);
            Write32(v);
        }
        public void Write32(int _index, Int32 _val)
        {
            UInt32 v = unchecked((UInt32)_val);
            Write32(_index, v);
        }
        #endregion
    }
}
