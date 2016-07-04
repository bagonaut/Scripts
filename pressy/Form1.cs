using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;


namespace WindowsFormsApplication1
{
    public partial class Form1 : Form
    {
        [DllImport("user32.dll")]
        static extern bool AttachThreadInput(uint idAttach, uint idAttachTo,   bool fAttach);
        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern IntPtr SetFocus(IntPtr hWnd);

        public Form1()
        {
            InitializeComponent();

            //string targetApp = "java";
            for (int i = 0; i < 100; i++)
            {
                //try // worth a try
                //{
                //    Microsoft.VisualBasic.Interaction.AppActivate(targetApp);
                //}
                //catch (System.ArgumentException)
                //{
                //    int x = 1;
                //}
                // more java treachery
                uint myTid = (uint)Environment.CurrentManagedThreadId;
                uint PStid;
                bool toBreak = false;
                bool.TryParse(Environment.GetEnvironmentVariable("toBreak"), out toBreak);

                bool swaResult;
                bool sfwResult;
                IntPtr sfResult;
                if (uint.TryParse(Environment.GetEnvironmentVariable("androidSetupPStid"), out PStid) )
                {
                    

                    if (toBreak)
                    {
                        Debugger.Break();
                    }

                    AttachThreadInput(myTid, PStid, true);
                    IntPtr psTid = new IntPtr(Convert.ToInt32(PStid));
                    swaResult = ShowWindowAsync(psTid, 5);
                    sfwResult = SetForegroundWindow(psTid);
                    sfResult = SetFocus(psTid);
                }
                
                //Form1.AttachThreadInput()


                SendKeys.SendWait("y"); // press y anyways
                SendKeys.SendWait("~");
                System.Threading.Thread.Sleep(1000);
            }
            System.Threading.Thread.CurrentThread.Abort();
        }
    }
}
