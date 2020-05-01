#Function to Output errors, verbose messages or warning
function Add-ClassTypes
{
    #We don't want to add the same types again and again.
    if ($script:RunFirstTime)
    {
        $pathToFormattingFile = (Join-Path  $PSScriptRoot $script:FormattingFile)
        $ClassDefinitionGroupedEvents = @"
            using System;
            using System.Globalization;
            using System.Collections;
            namespace Microsoft.PowerShell.xDscDiagnostics
            {
                public class GroupedEvents {
                        public int SequenceId;
                        public System.DateTime TimeCreated;
                        public string ComputerName;
                        public Guid? JobID = null;
                        public System.Array AllEvents;
                        public int NumberOfEvents;
                        public System.Array AnalyticEvents;
                        public System.Array DebugEvents;
                        public System.Array NonVerboseEvents;
                        public System.Array VerboseEvents;
                        public System.Array OperationalEvents;
                        public System.Array ErrorEvents;
                        public System.Array WarningEvents;
                        public string Result;

                   }
            }
"@
        $ClassDefinitionTraceOutput = @"
               using System;
               using System.Globalization;
               namespace Microsoft.PowerShell.xDscDiagnostics
               {
                   public enum EventType {
                        DEBUG,
                        ANALYTIC,
                        OPERATIONAL,
                        ERROR,
                        VERBOSE
                   }
                   public class TraceOutput {
                        public EventType EventType;
                        public System.DateTime TimeCreated;
                        public string Message;
                        public string ComputerName;
                        public Guid? JobID = null;
                        public int SequenceID;
                        public System.Diagnostics.Eventing.Reader.EventRecord Event;
                   }
               }

"@
        Add-Type -Language CSharp -TypeDefinition $ClassDefinitionGroupedEvents
        Add-Type -Language CSharp -TypeDefinition $ClassDefinitionTraceOutput
        #Update-TypeData -TypeName TraceOutput -DefaultDisplayPropertySet EventType, TimeCreated, Message
        Update-FormatData  -PrependPath $pathToFormattingFile

        $script:RunFirstTime = $false; #So it doesnt do it the second time.
    }
}
