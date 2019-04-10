using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using HIVCE.Common;
using HIVCE.Common.Entities;
using Application.Presentation;
using System.Data;
using System.Configuration;
using HIVCE.BusinessLayer;
using Interface.HIVCE;

namespace PresentationApp.HIVCE
{
    public partial class MoriskyAdherence : System.Web.UI.Page
    {
        int PatientId = 0;
        int locationId;
        int userId;
        int visitPK = 0;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (!object.Equals(Session["PatientId"], null))
                {
                    PatientId = Convert.ToInt32(Session["PatientId"]);
                }
                if (!object.Equals(Session["AppLocationId"], null))
                {
                    locationId = Convert.ToInt32(Session["AppLocationId"]);
                }
                if (!object.Equals(Session["AppUserId"], null))
                {
                    userId = Convert.ToInt32(Session["AppUserId"]);
                }
                if (!object.Equals(Session["PatientVisitId"], null))
                {
                    visitPK = Convert.ToInt32(Session["PatientVisitId"]);
                }

                if (!object.Equals(Request.QueryString["data"], null))
                {
                    string response = string.Empty;
                    if (!object.Equals(Request.QueryString["data"], null))
                    {
                        if (Request.QueryString["data"].ToString() == "getdata")
                        {
                            response = GetMoriskyData(PatientId, visitPK);
                            SendResponse(response);
                        }
                    }

                    if (Request.QueryString["data"].ToString() == "savedata")
                    {
                        System.IO.StreamReader sr = new System.IO.StreamReader(Request.InputStream);
                        string jsonString = "";
                        jsonString = sr.ReadToEnd();

                        response = SaveData(jsonString, PatientId, visitPK);
                        SendResponse(response);
                    }
                }

            }
        }

        private string SaveData(string nodeJson, int ptn_pk, int visitPK)
        {
            string result = string.Empty;
            ResponseType ObjResponse = new ResponseType();
            try
            {
                MAdherence adcObj = SerializerUtil.ConverToObject<MAdherence>(nodeJson);
                IClinicalEncounter blObj = (IClinicalEncounter)ObjectFactory.CreateInstance("HIVCE.BusinessLayer.BLClinicalEncounter, HIVCE.BusinessLayer");
                adcObj.Ptn_pk = ptn_pk;
                adcObj.Visit_Id = visitPK;

                int flag = blObj.SaveUpdateMoriskyData(adcObj, ptn_pk, visitPK, userId, locationId, DateTime.Now);
                if (flag == 1)
                {
                    ObjResponse.Success = EnumUtil.GetEnumDescription(Success.True);
                }
                else
                {
                    ObjResponse.Success = EnumUtil.GetEnumDescription(Success.False);
                }
            }
            catch (Exception ex)
            {
                ObjResponse.Success = EnumUtil.GetEnumDescription(Success.False);
            }
            finally
            {

            }

            result = SerializerUtil.ConverToJson<ResponseType>(ObjResponse);
            return result;
        }

        private void SendResponse(string data)
        {
            Response.Clear();
            Response.ContentType = "application/json";
            Response.AddHeader("Content-type", "text/json");
            Response.AddHeader("Content-type", "application/json");
            Response.Write(data);
            Response.End();
        }

        private string GetMoriskyData(int ptn_pk, int visitPK)
        {
            string result = string.Empty;
            try
            {
                IClinicalEncounter blObj = (IClinicalEncounter)ObjectFactory.CreateInstance("HIVCE.BusinessLayer.BLClinicalEncounter, HIVCE.BusinessLayer");
                MAdherence objTP = blObj.GetMoriskyData(ptn_pk, visitPK);
                result = SerializerUtil.ConverToJson<MAdherence>(objTP);
            }
            catch (Exception ex)
            {
                ResponseType response = new ResponseType() { Success = EnumUtil.GetEnumDescription(Success.False) };
                result = SerializerUtil.ConverToJson<ResponseType>(response);
            }
            finally
            {

            }
            return result;
        }
    }
}