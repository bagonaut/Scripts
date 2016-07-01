using System.Windows.Forms;

namespace WindowsFormsApplication1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            string targetApp = "java";
            for (int i = 0; i < 100; i++)
            {
                try // worth a try
                {
                    Microsoft.VisualBasic.Interaction.AppActivate(targetApp);
                }
                catch (System.ArgumentException)
                {
                    int x = 1;
                }
                
                SendKeys.SendWait("y"); // press y anyways
                SendKeys.SendWait("~");
                System.Threading.Thread.Sleep(1000);
            }
            System.Threading.Thread.CurrentThread.Abort();
        }
    }
}
