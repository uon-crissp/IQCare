﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Reporting;

namespace PresentationApp.Reports
{
    public partial class frmPatRegReport : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Telerik.Reporting.Processing.ReportProcessor reportProcessor = new Telerik.Reporting.Processing.ReportProcessor();
            System.Collections.Hashtable deviceInfo = new System.Collections.Hashtable();
            TypeReportSource reportSource = new TypeReportSource();
            reportSource.TypeName = typeof(PatientRegistrationForm).AssemblyQualifiedName;
            ReportSource myrep = reportSource;

            myrep.Parameters.Add(new Telerik.Reporting.Parameter("patientpk", Session["PatientId"].ToString()));

            reportViewer1.ReportSource = reportSource;
            reportViewer1.ParametersAreaVisible = false;
            this.reportViewer1.RefreshReport();
        }
    }
}