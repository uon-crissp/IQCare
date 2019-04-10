var arrMMAS4Score = [];
var arrMMAS8Score = [];
var arrICDData = [];
var arrICDBaseData = [];
var arrICD10 = [];
var arrNxtAppointment = [];
var arrPatientClassification = [];

function InitMoriskyControls() {
    window.scrollTo(0, 0);

    $("#divOtherQesAdherence").css("visibility", "hidden");
    $("#divOtherQesAdherence").css("display", "none");

    $("#chkForgotMed").bootstrapSwitch('state', false);
    $("#chkCarelessMed").bootstrapSwitch('state', false);
    $("#chkWorseTakingMed").bootstrapSwitch('state', false);
    $("#chkFeelBetterMed").bootstrapSwitch('state', false);

    $("#chkYesterdayMed").bootstrapSwitch('state', false);
    $("#chkSymptomUnderControl").bootstrapSwitch('state', false);
    $("#chkStickingTreatmentPlan").bootstrapSwitch('state', false);

    $("#chkForgotMed").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS4Score("fm", GetSwitchValue("chkForgotMed"));
    });
    $("#chkCarelessMed").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS4Score("cm", GetSwitchValue("chkCarelessMed"));
    });
    $("#chkWorseTakingMed").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS4Score("wtm", GetSwitchValue("chkWorseTakingMed"));
    });
    $("#chkFeelBetterMed").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS4Score("fbm", GetSwitchValue("chkFeelBetterMed"));
    });

    $("#chkYesterdayMed").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS8Score("ym", GetSwitchValue("chkYesterdayMed"));
    });
    $("#chkSymptomUnderControl").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS8Score("suc", GetSwitchValue("chkSymptomUnderControl"));
    });
    $("#chkStickingTreatmentPlan").on('switchChange.bootstrapSwitch', function (event, state) {
        CalculateMMAS8Score("stp", GetSwitchValue("chkStickingTreatmentPlan"));
    });

    BindMoriskyData();
}

function CalculateMMAS4Score(ref, val) {
    var chkData = $.grep(arrMMAS4Score, function (e) { return e.Ref.toLowerCase() == ref.toLowerCase(); });
    if (jQuery.isEmptyObject(chkData) == true) {
        arrMMAS4Score.push({ Ref: ref, Val: val });
    }
    else {
        $.each(arrMMAS4Score, function (index, arrD) {
            if (jQuery.isEmptyObject(arrD) == false) {
                if (arrD.Ref.toLowerCase() == ref.toLowerCase()) {
                    arrD.Val = val;
                }
            }
        });
    }
    CalculateMMSImpl();
}

function CalculateMMAS8Score(ref, val) {
    var chkData = $.grep(arrMMAS8Score, function (e) { return e.Ref.toLowerCase() == ref.toLowerCase(); });
    if (jQuery.isEmptyObject(chkData) == true) {
        if (ref == "ym") {
            if (val == 1) {
                val = 0;
            }
            else {
                val = 1;
            }
        }
        arrMMAS8Score.push({ Ref: ref, Val: val });
    }
    else {
        $.each(arrMMAS8Score, function (index, arrD) {
            if (jQuery.isEmptyObject(arrD) == false) {
                if (arrD.Ref.toLowerCase() == ref.toLowerCase()) {
                    arrD.Val = val;
                }
            }
        });
    }

    CalculateMMSImpl();
}

function CalculateRBMMAS8Score(ctrlName) {
    var val = 0;
    var ref = "rm";

    if (ctrlName.parentNode.parentNode.innerText.trim().toLowerCase() == "never / rarely") {
        val = 0;
    }
    else if (ctrlName.parentNode.parentNode.innerText.trim().toLowerCase() == "once in a while") {
        val = .25;
    }
    else if (ctrlName.parentNode.parentNode.innerText.trim().toLowerCase() == "sometimes") {
        val = .50;
    }
    else if (ctrlName.parentNode.parentNode.innerText.trim().toLowerCase() == "usually") {
        val = .75;
    }
    else if (ctrlName.parentNode.parentNode.innerText.trim().toLowerCase() == "all the time") {
        val = 1;
    }

    var chkData = $.grep(arrMMAS8Score, function (e) { return e.Ref.toLowerCase() == ref.toLowerCase(); });
    if (jQuery.isEmptyObject(chkData) == true) {
        arrMMAS8Score.push({ Ref: ref, Val: val });
    }
    else {
        $.each(arrMMAS8Score, function (index, arrD) {
            if (jQuery.isEmptyObject(arrD) == false) {
                if (arrD.Ref.toLowerCase() == ref.toLowerCase()) {
                    arrD.Val = val;
                }
            }
        });
    }

    CalculateMMSImpl();
}

function CalculateMMSImpl() {
    var totMMAS8Score = 0.0;

    $.each(arrMMAS8Score, function (index, arrD) {
        if (jQuery.isEmptyObject(arrD) == false) {
            totMMAS8Score += parseFloat(arrD.Val);
        }
    });

    var totMMAS4Score = 0;

    $.each(arrMMAS4Score, function (index, arrD) {
        if (jQuery.isEmptyObject(arrD) == false) {
            totMMAS4Score += parseInt(arrD.Val);
        }
    });

    $("#txtMMAS4Score").val(totMMAS4Score);

    if (parseInt(totMMAS4Score) == 0) {
        $("#txtMMAS4Rating").val("Good");
        $("#divOtherQesAdherence").css("visibility", "hidden");
        $("#divOtherQesAdherence").css("display", "none");
    }
    else if (parseInt(totMMAS4Score) >= 1 && parseInt(totMMAS4Score) <= 2) {
        $("#txtMMAS4Rating").val("Inadequate");
        $("#divOtherQesAdherence").css("visibility", "visible");
        $("#divOtherQesAdherence").css("display", "inline");
    }
    else if (parseInt(totMMAS4Score) >= 3 && parseInt(totMMAS4Score) <= 4) {
        $("#txtMMAS4Rating").val("Poor");
        $("#divOtherQesAdherence").css("visibility", "visible");
        $("#divOtherQesAdherence").css("display", "inline");
    }

    if (totMMAS4Score > 0) {
        totMMAS8Score = parseFloat(totMMAS8Score) + parseFloat(totMMAS4Score);

        $("#txtMMAS8Score").val(totMMAS8Score);

        if (parseInt(totMMAS8Score) == 0) {
            $("#txtMMAS8Rating").val("Good");
            $("#txtMMAS8Suggestion").val("");
        }
        else if (parseInt(totMMAS8Score) >= 1 && parseInt(totMMAS8Score) <= 2) {
            $("#txtMMAS8Rating").val("Inadequate");
            $("#txtMMAS8Suggestion").val("");
        }
        else if (parseInt(totMMAS8Score) >= 3 && parseInt(totMMAS8Score) <= 4) {
            $("#txtMMAS8Rating").val("Poor");
            $("#txtMMAS8Suggestion").val("Refer to Counselor");
        }
    }
    else {
        $("#txtMMAS8Score").val("0");
        $("#txtMMAS8Rating").val("Good");
        $("#txtMMAS8Suggestion").val("");
    }
}

function BindMoriskyData() {
    $.ajax({
        type: "POST",
        url: "MoriskyAdherence.aspx?data=getdata",
        //data: JSON.stringify(nodeId),
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        async: true,
        cache: false,
        beforeSend: function () {
        },
        success: function (response) {
            console.log(response);
            var responseSuccess = response.Success;
            if (responseSuccess != null) {
                if (responseSuccess == "false") {
                    customAlert(errorMessage);
                }
            }
            else {
                BindMoriskyxControls(response);
            }

        },
        error: function (msg) {
        }
    });

    $('input:radio[name=rbRM]').on('ifChecked', function (event) {
        $(this).closest("input").attr('checked', true);
        CalculateRBMMAS8Score(this);
    });
    $('input:radio[name=rbRM]').on('ifUnchecked', function (event) {
        $(this).closest("input").attr('checked', false);
        CalculateRBMMAS8Score(this);
    });
}

function BindMoriskyxControls(response) {

    if (jQuery.isEmptyObject(response.MPA.ISFM) == false) {
        if (response.MPA.ISFM > 0) {
            $("#chkForgotMed").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISCM) == false) {
        if (response.MPA.ISCM > 0) {
            $("#chkCarelessMed").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISWTM) == false) {
        if (response.MPA.ISWTM > 0) {
            $("#chkWorseTakingMed").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISFBM) == false) {
        if (response.MPA.ISFBM > 0) {
            $("#chkFeelBetterMed").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISYM) == false) {
        if (response.MPA.ISYM > 0) {
            $("#chkYesterdayMed").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISSUC) == false) {
        if (response.MPA.ISSUC > 0) {
            $("#chkSymptomUnderControl").bootstrapSwitch('state', true);
        }
    }

    if (jQuery.isEmptyObject(response.MPA.ISSTP) == false) {
        if (response.MPA.ISSTP > 0) {
            $("#chkStickingTreatmentPlan").bootstrapSwitch('state', true);
        }
    }

    $("input:radio[name=rbRM][value=" + response.MPA.RM + "]").attr('checked', 'checked');
    $("input:radio[name=rbRM]").iCheck('update');

    $("#txtMMAS4Score").val(response.MPA.MMAS4S);
    $("#txtMMAS4Rating").val(response.MPA.MMAS4R);
    $("#txtMMAS8Score").val(response.MPA.MMAS8S);
    $("#txtMMAS8Rating").val(response.MPA.MMAS8R);
    $("#txtMMAS8Suggestion").val(response.MPA.MMAS8SG);
	
    $.hivce.loader('hide');
}

function SaveMoriskyData() {
    $.hivce.loader('show');

    var MoriskyxData = PrepareMoriskyxData();

    PostMoriskyxData(MoriskyxData);
}

function PrepareMoriskyxData() {
    rowMoriskyxData = [];

    var chkARTSideEffect = GetSwitchValue("chkARTSideEffect");

    var chkForgotMed = GetSwitchValue("chkForgotMed");
    var chkCarelessMed = GetSwitchValue("chkCarelessMed");
    var chkWorseTakingMed = GetSwitchValue("chkWorseTakingMed");
    var chkFeelBetterMed = GetSwitchValue("chkFeelBetterMed");

    var txtMMAS4Score = $("#txtMMAS4Score").val();
    var txtMMAS4Rating = $("#txtMMAS4Rating").val();

    var chkYesterdayMed = GetSwitchValue("chkYesterdayMed");
    var chkSymptomUnderControl = GetSwitchValue("chkSymptomUnderControl");
    var chkStickingTreatmentPlan = GetSwitchValue("chkStickingTreatmentPlan");

    var rbRM = $("input:radio[name=rbRM]:checked").val();
    var urbRM = (rbRM === undefined) ? 0 : rbRM;

    var txtMMAS8Score = $("#txtMMAS8Score").val();
    var txtMMAS8Rating = $("#txtMMAS8Rating").val();
    var txtMMAS8Suggestion = $("#txtMMAS8Suggestion").val();

    var arrMADE = [];
    arrMADE.push({
        Ptn_Pk: 0,
        LId: 0,
        VId: 0,
        ISFM: chkForgotMed,
        ISCM: chkCarelessMed,
        ISWTM: chkWorseTakingMed,
        ISFBM: chkFeelBetterMed,
        MMAS4S: txtMMAS4Score,
        MMAS4R: txtMMAS4Rating,
        ISYM: chkYesterdayMed,
        ISSUC: chkSymptomUnderControl,
        ISSTP: chkStickingTreatmentPlan,
        RM: urbRM,
        MMAS8S: txtMMAS8Score,
        MMAS8R: txtMMAS8Rating,
        MMAS8SG: txtMMAS8Suggestion
    });

    return arrMADE[0];
}

function PostMoriskyxData(rowData) {

    var action = "savedata";
    var rowData1 = rowData;
    var errorMsg = "";
    activePage = getPageName() + '.aspx';

	$.hivce.loader('show');
	var responseObject = null;
	$.ajax({
		type: "POST",
		url: activePage + "?data=" + action,
		data: JSON.stringify(rowData1),
		contentType: "application/json;charset=utf-8",
		dataType: "json",
		async: true,
		cache: false,
		beforeSend: function () {
		},
		success: function (response) {
			var responseSuccess = response.Success;
			if (responseSuccess == "true") {
				customAlert("Morisky data " + dataSuccessMessage.toLowerCase());
				window.location.assign("../ClinicalForms/frmPatient_History.aspx?&sts=0");
			}
			else {
				if (responseSuccess == "false") {
					customAlert(errorMessage);
				}
				else {
					customAlert(responseSuccess);
				}
			}
			$.hivce.loader('hide');
		},
		error: function (xhr, textStatus, errorThrown) {
			ShowErrorMessage(msg);
		}
	});
}