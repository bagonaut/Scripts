using System;
using System.Diagnostics;
using System.IO;
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

                string logFileName = Path.Combine(Path.GetTempPath(), "EulaAcceptor.log");
                uint myTid = (uint)AppDomain.GetCurrentThreadId();
                uint PStid;
                uint psHwnd;
                bool toBreak = false;
                bool.TryParse(Environment.GetEnvironmentVariable("toBreak"), out toBreak);
                File.AppendAllText(logFileName, " Android Setup Powershell toBreak: " + toBreak.ToString() + Environment.NewLine);
                bool attachResult;
                bool swaResult;
                bool sfwResult;
                IntPtr sfResult;
                //$env:androidSetupPShwnd = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
                //[Environment]::SetEnvironmentVariable("androidSetupPShd", $Env:androidSetupPShwnd, [System.EnvironmentVariableTarget]::Machine)
                uint.TryParse(Environment.GetEnvironmentVariable("androidSetupPShwnd"), out psHwnd);
                if (uint.TryParse(Environment.GetEnvironmentVariable("androidSetupPStid"), out PStid) )
                {
                    File.AppendAllText(logFileName, " Android Setup Powershell Thread ID: " + PStid.ToString() + Environment.NewLine);
                    File.AppendAllText(logFileName, " Android Setup Powershell Main Window Handle: " + psHwnd.ToString() + Environment.NewLine);
                    File.AppendAllText(logFileName, " pressy Thread ID: " + myTid.ToString() + Environment.NewLine);

                    if (toBreak)
                    {
                        Debugger.Break();
                    }

                    attachResult = AttachThreadInput(myTid, PStid, true);
                    File.AppendAllText(logFileName, " Attach Result: " + attachResult.ToString() + Environment.NewLine);
                    IntPtr pshwnd = new IntPtr(Convert.ToInt32(psHwnd));
                    swaResult = ShowWindowAsync(pshwnd, 5);
                    File.AppendAllText(logFileName, " ShowWindowAsync Result: " + swaResult.ToString() + Environment.NewLine);
                    sfwResult = SetForegroundWindow(pshwnd);
                    File.AppendAllText(logFileName, " ShowForegroundWindow Result: " + sfwResult.ToString() + Environment.NewLine);
                    sfResult = SetFocus(pshwnd);
                    File.AppendAllText(logFileName, " SetFocus Result: " + sfResult.ToString() + Environment.NewLine);
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
