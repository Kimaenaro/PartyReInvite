local PRI_PlayerName = nil;
local PRI_Timer = 0;
local PRI_TimerActive = false;
local PRI_TimerInterval = 1.0;
local PRI_LastUpdate = 0;
local PRI_TimerOutput = 0;
local PRI_TimerPosX = (GetScreenWidth() / 2) - 30;
local PRI_TimerPosY = (GetScreenHeight() / 2) * -1;

PRI_TimeLeft = 0;
PRI_LastTime = nil;


function PRI_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PARTY_MEMBERS_CHANGED");
	this:RegisterEvent("CHAT_MSG_SYSTEM");
	this:RegisterEvent("PARTY_INVITE_REQUEST");
	
	SlashCmdList["PRI"] = PRI_SlashCommand;
	SLASH_PRI1 = "/PRI";
end

function PRI_HelpMSG(var)
	
	if (var == "help" or "timer" or "test") then
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."slash commands:");
	end
	
	if (var == "help") then
		DEFAULT_CHAT_FRAME:AddMessage(" /pri - show this message.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri enable on - enable addon.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri enable off - disable addon.");
	
		DEFAULT_CHAT_FRAME:AddMessage(" /pri invited name - set player name to be tracked and invited back.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri invited name - set player to accept invites only from.");
		
		DEFAULT_CHAT_FRAME:AddMessage(" /pri accept on/off - enables/disables auto-accepting party invites.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri decline on/off - enables/disables auto-decline invites from players except inviter.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri notify on/off - enables/disables auto sending whispers to reinvited player.");
	end
		
	if (var == "help") or (var =="timer") then
		DEFAULT_CHAT_FRAME:AddMessage(" /pri timer start - to start timer.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri timer stop - to stop timer.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri timer reset - to reset timer position.");
		DEFAULT_CHAT_FRAME:AddMessage(" /pri timer cancel - cancel auto-re-invite timer.");
	end
end

function PRI_SlashCommand(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	
	
	if (msg == "") then
		PRI_HelpMSG("help")
	else
	
		if strlower(cmd) == "timer" then
			if strlower(args) == "start" then
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."starting timer (it wont start if addon disabled).");
				PRI_TimerStart();
			elseif strlower(args) == "stop" then
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."stoping timer.");
				PRI_TimerStop();
			elseif strlower(args) == "resetpos" then
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."reseting timer position.");
				PRI_TimerSetDefaultPos();
			elseif strlower(args) == "cancel" then
				PRI_TimerCancel();
			else
				PRI_HelpMSG("timer");
			end
		elseif strlower(cmd) == "settings" then
			DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."showing settings.");
			PRI_SettingsFramePop();
		elseif strlower(cmd) == "invited" then
			if (args ~= "") then
				PRI_InvitedName(args);
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri invited name\".");
			end
		elseif strlower(cmd) == "inviter" then
			if (args ~= "") then
				PRI_InviterName(args);
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri inviter name\".");
			end
		elseif strlower(cmd) == "enable" then
			if strlower(args) == "on" then
				PRI_Enabler(true)
			elseif strlower(args) == "off" then
				PRI_Enabler(false)
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri enable on\" or \"/pri enable off\".");
			end
		elseif strlower(cmd) == "accept" then
			if strlower(args) == "on" then
				PRI_EnablerAccept(true)
			elseif strlower(args) == "off" then
				PRI_EnablerAccept(false)
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri accept on\" or \"/pri accept off\".");
			end
		elseif strlower(cmd) == "decline" then
			if strlower(args) == "on" then
				PRI_EnablerDecline(true)
			elseif strlower(args) == "off" then
				PRI_EnablerDecline(false)
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri decline on\" or \"/pri decline off\".");
			end
		elseif strlower(cmd) == "notify" then
			if strlower(args) == "on" then
				PRI_NotifyFunc(true)
			elseif strlower(args) == "off" then
				PRI_NotifyFunc(false)
			else
				DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."usage - \"/pri notify on\" or \"/pri notify off\".");
			end
		else
			PRI_HelpMSG("help")
		end
	end
end


function PRI_TimerStart()
	if PRI_Enabled then
		PRI_TimeLeft = tonumber(PRI_Timerino)
		PRI_LastTime = GetTime()
		PRI_TimerFrame:SetScript("OnUpdate", PRI_TimerTick)
		PRI_TimerFramePop();
	end
end

function PRI_TimerTick()
	if (PRI_TimeLeft <= 0) then
		PRI_TimerStop()
	else
		local t = GetTime()
		local td = t - PRI_LastTime
		PRI_TimeLeft = PRI_TimeLeft - td
		
		PRI_LastTime = t
		
		if (t - PRI_LastUpdate >= PRI_TimerInterval) then
			PRI_LastUpdate = t
		
			PRI_TimerOutput = math.floor(PRI_TimeLeft + 0.5)
			if PRI_TimerTXT then
                PRI_TimerTXT:SetText(PRI_TimerOutput)
            end
		end
		
	end

end


function PRI_TimerStop()
	if PRI_Enabled then
		if PRI_TimerTXT then
			PRI_TimeLeft = 0
			PRI_TimerFrame:SetScript("OnUpdate", nil)
			if (PRI_InvitedNameVar) then
				InviteByName(PRI_InvitedNameVar)
			end
			PRI_TimerTXT:Hide()
		end
	end
end


function PRI_TimerCancel()
	if PRI_TimerTXT then
		PRI_TimeLeft = 0
		PRI_TimerFrame:SetScript("OnUpdate", nil)
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."Timer canceled - stoping timer with no auto-invite.");
		PRI_TimerTXT:Hide()
	end
end


function PRI_InvitedName(invitedName)
	if (invitedName == "") then
		return;
	end;
	
	PRI_Settings[PRI_PlayerName]["invWho"] = invitedName;
	PRI_InvitedNameVar = invitedName;
	DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."Player \""..invitedName.."\" will be auto-invited.");
end


function PRI_InviterName(inviterName)
	if (inviterName == "") then
		return;
	end;
	
	PRI_Settings[PRI_PlayerName]["whoInv"] = inviterName;
	PRI_InviterNameVar = inviterName;
	DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."invites from \""..inviterName.."\" will be auto-accepted.");
end


function PRI_SetTimerTo(tim)
	if (tim == "") then
		return;
	end;
	
	if PRI_OnlyDigits(tim) then
		PRI_Settings[PRI_PlayerName]["Timer"] = tim;
		PRI_Timerino = tim;
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."auto re-invite timer now set to: "..tim.." seconds.");
	else
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("error").."incorrect timer settings entered, reverting timer changes.");
	end
end


function PRI_UpdateIcon()
    local texture = PartyReInvite_IconTexture
	
    if not texture then 
		return 
	end
	
    if PRI_Enabled then
        texture:SetTexture("Interface\\AddOns\\PartyReInvite\\Images\\Icon_On")
    else
        texture:SetTexture("Interface\\AddOns\\PartyReInvite\\Images\\Icon_Off")
    end
end


function PRI_Enabler(var)
	if (var == "") then
		var = true
	end;
	
	PRI_Settings[PRI_PlayerName]["Enabled"] = var;
	PRI_Enabled = var;
	
    PRI_UpdateIcon()
	
	if var then
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."addon is now active.");
	else
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."addon is now disabled.");
		if (PRI_TimeLeft > 0) then
			PRI_TimerCancel();
		end
	end
end


function PRI_EnablerAccept(var)
	if (var == "") then
		var = true
	end;
	
	PRI_Settings[PRI_PlayerName]["AcceptInvites"] = var;
	PRI_AccInvites = var;
	
	if var then
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."all party invites will be auto-accepted.");
	else
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."auto-accepting party invites is OFF.");
	end
end


function PRI_EnablerDecline(var)
	if (var == "") then
		var = true
	end;
	
	PRI_Settings[PRI_PlayerName]["DeclineInvites"] = var;
	PRI_DecInvites = var;
	
	if var then
		if PRI_InviterNameVar then
			DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."will accept invites only from "..PRI_InviterNameVar..".");
		else
			DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."will accept invites only from set player (need to asign name).");
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."will accept invites from any player (if auto-accept is ON).");
	end
end


function PRI_NotifyFunc(var)
	if (var == "") then
		var = true
	end;
	
	PRI_Settings[PRI_PlayerName]["NotifyPlayer"] = var;
	PRI_Notify = var;
	
	if var then
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."re-invited player wil now recieve notifications on group leaving.");
	else
		DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."notifications to other players are off.");
	end
end


function PRI_TimerSetDefaultPos()
	PRI_TimerPosX = (GetScreenWidth() / 2) - 30;
	PRI_TimerPosY = (GetScreenHeight() / 2) * -1;
	
	if PRI_TimerTXT then
		PRI_TimerTXT:SetPoint("TOPLEFT", UIParent, "TOPLEFT", PRI_TimerPosX, PRI_TimerPosY)
	end
end


function PRI_SaveTimerPos(x, y)
	if (x == "") or (y == "") then
		x = 180;
		y = -100;
	end;
	
	PRI_Settings[PRI_PlayerName]["TimerPosX"] = x;
	PRI_Settings[PRI_PlayerName]["TimerPosY"] = y;
end


function PRI_OnEvent()
	if ( event == "VARIABLES_LOADED" ) then
		PRI_PlayerName = UnitName("player").." of "..GetCVar("realmName");

		if ( PRI_Settings == nil ) then 
			PRI_Settings = {};
		end
		
		if ( PRI_Settings[PRI_PlayerName] == nil ) then 
			PRI_Settings[PRI_PlayerName] = {};
		end
		
		if ( PRI_Settings[PRI_PlayerName]["Timer"] == nil ) then 
			PRI_Settings[PRI_PlayerName]["Timer"] = 50;
		end

		if (PRI_ButtonPosition == nil) then
			PRI_ButtonPosition = 60;
		end
	
		if (PRI_Settings[PRI_PlayerName]["Enabled"]) then
			PRI_Enabled = PRI_Settings[PRI_PlayerName]["Enabled"];
		elseif (PRI_Settings[PRI_PlayerName]["Enabled"]) == nil then
			local PRI_Enabled = true;
		end
		
		if (PRI_Settings[PRI_PlayerName]["Timer"]) then
			PRI_Timerino = PRI_Settings[PRI_PlayerName]["Timer"];
		else
			local PRI_Timerino = 50;
		end
		
		if (PRI_Settings[PRI_PlayerName]["invWho"]) then
			PRI_InvitedNameVar = PRI_Settings[PRI_PlayerName]["invWho"];
		else
			local PRI_InvitedNameVar = nil;
		end
		
		if (PRI_Settings[PRI_PlayerName]["whoInv"]) then
			PRI_InviterNameVar = PRI_Settings[PRI_PlayerName]["whoInv"];
		else
			local PRI_InviterNameVar = nil;
		end
		

		if (PRI_Settings[PRI_PlayerName]["AcceptInvites"]) then
			PRI_AccInvites = PRI_Settings[PRI_PlayerName]["AcceptInvites"];
		else
			local PRI_AccInvites = nil;
		end
		
		if (PRI_Settings[PRI_PlayerName]["DeclineInvites"]) then
			PRI_DecInvites = PRI_Settings[PRI_PlayerName]["DeclineInvites"];
		else
			local PRI_DecInvites = nil;
		end
		
		if (PRI_Settings[PRI_PlayerName]["NotifyPlayer"]) then
			PRI_Notify = PRI_Settings[PRI_PlayerName]["NotifyPlayer"];
		else
			local PRI_Notify = nil;
		end
		

		if (PRI_Settings[PRI_PlayerName]["TimerPosX"]) then
			PRI_TimerPosX = PRI_Settings[PRI_PlayerName]["TimerPosX"];
		else
			local PRI_TimerPosX = 160;
		end
		
		
		if (PRI_Settings[PRI_PlayerName]["TimerPosY"]) then
			PRI_TimerPosY = PRI_Settings[PRI_PlayerName]["TimerPosY"];
		else
			local PRI_TimerPosY = -100;
		end
		
		PRI_UpdateIcon()
		UIDropDownMenu_Initialize( getglobal( "PRI_DropDownMenu" ), PRI_DropDownMenu_OnLoad, "MENU" );
		PRIButton_SetPosition(PRI_ButtonPosition)
	end
	

	if PRI_Enabled then
		if ( event == "CHAT_MSG_SYSTEM" ) and (PRI_InvitedNameVar) then
			if arg1 and string.find(arg1, "leaves the party") then
				if arg1 and string.find(arg1, PRI_InvitedNameVar) then
					DEFAULT_CHAT_FRAME:AddMessage(PRI_Name().."Tracked player leaves party, starting timer for re-invite.");
					if PRI_Notify then
						SendChatMessage("PRI: you will be re-invited back in "..PRI_Timerino.." seconds.", "WHISPER", nil, PRI_InvitedNameVar);
					end
					PRI_TimerStart()
				end
			elseif arg1 and string.find(arg1, "joins the party") and (PRI_TimeLeft > 0) then
				PRI_TimerCancel();
			end
		end
	end
	
	-- Accepting group invites here --
	
	if PRI_Enabled then
		if ( event == "CHAT_MSG_SYSTEM" ) then
			if arg1 and string.find(arg1, "has invited you to join a group") then
				if PRI_InviterNameVar then
					if arg1 and not string.find(arg1, PRI_InviterNameVar) then
						if PRI_DecInvites then
							DeclineGroup();
							StaticPopup_Hide("PARTY_INVITE");
							DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("error").."You has been invited to party, inviter name doesn't match, rejecting.");
						end
					elseif arg1 and string.find(arg1, PRI_InviterNameVar) and PRI_DecInvites and PRI_AccInvites then
						AcceptGroup();
						StaticPopup_Hide("PARTY_INVITE");
					end
				elseif PRI_DecInvites and not PRI_InviterNameVar then
					DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("error").."Auto-declining is ON, but name of inviter player not assigned.");
					if PRI_AccInvites and PRI_DecInvites then
						DEFAULT_CHAT_FRAME:AddMessage(PRI_Name("ok").."accepting invite, because auto-accept is ON.");
						AcceptGroup();
						StaticPopup_Hide("PARTY_INVITE");
					end
				end
				
				if PRI_AccInvites and not PRI_DecInvites then
					AcceptGroup();
					StaticPopup_Hide("PARTY_INVITE");
				end
			end
		end
	end
end


function PRI_Name(state)
	if (state == "error") then
		return("|cffE66700Party RE-Invite:|r ")
	else
		return("|cff6ACAFFParty RE-Invite:|r ")
	end
end


function PRI_OnlyDigits(input)
    if type(input) ~= "string" then
        return false
    end

    if input == "" then
        return false
    end

    for i = 1, strlen(input) do
        local char = strbyte(input, i)
		
        if char < 48 or char > 57 then
            return false
        end
    end

    return true
end


-- GUI --
function PRI_DropDownMenu_OnLoad()

	local title	= {
		text 		= "Party Re Invite is:",
		isTitle		= true,
		owner 		= this:GetParent(),
		justifyH 	= "CENTER",
	};
	UIDropDownMenu_AddButton( title, UIDROPDOWNMENU_MENU_LEVEL );
	
	if PRI_Enabled then
		local info = {
			text 	= "|cff00FF00ON|r, click to toggle",
			func 			= function()
				PRI_Enabler(false)
			end,
			notCheckable 	= 0,
			owner 			= this:GetParent()
		};
		UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );
	else
		local info = {
			text 	= "|cffFF0000OFF|r, click to toggle",
			func 			= function()
				PRI_Enabler(true)
			end,
			notCheckable 	= 0,
			owner 			= this:GetParent()
		};
		UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );
	end


	title	= {
		text 		= "Invited player:",
		isTitle		= true,
		owner 		= this:GetParent(),
		justifyH 	= "LEFT",
	};
	UIDropDownMenu_AddButton( title, UIDROPDOWNMENU_MENU_LEVEL );
	
	local info = {
		text 	= PRI_CheckInvVar(PRI_InvitedNameVar),
		func 			= function()
			StaticPopup_Show("PRI_SetInvited");
		end,
		notCheckable 	= 1,
		owner 			= this:GetParent()
	};
	UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );

	title	= {
		text 		= "Accept only from:",
		isTitle		= true,
		owner 		= this:GetParent(),
		justifyH 	= "LEFT",
	};
	UIDropDownMenu_AddButton( title, UIDROPDOWNMENU_MENU_LEVEL );
	
	local info = {
		text 	= PRI_CheckInvVar(PRI_InviterNameVar),
		func 			= function()
			StaticPopup_Show("PRI_SetInviter");
		end,
		notCheckable 	= 1,
		owner 			= this:GetParent()
	};
	UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );

    local separator = {
        text        = ":::::::::::::::::::::::::::::::",
        isTitle     = true,
		justifyH 	= "CENTER",
        notCheckable = 1,
        owner       = this:GetParent()
    };
    UIDropDownMenu_AddButton( separator, UIDROPDOWNMENU_MENU_LEVEL );
	
	local info = {
		text 	= PRI_CheckInvVar("Settings"),
		func 			= function()
			PRI_SettingsFramePop();
		end,
		notCheckable 	= 1,
		owner 			= this:GetParent()
	};
	UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );

    local separator = {
        text        = ":::::::::::::::::::::::::::::::",
        isTitle     = true,
		justifyH 	= "CENTER",
        notCheckable = 1,
        owner       = this:GetParent()
    };
    UIDropDownMenu_AddButton( separator, UIDROPDOWNMENU_MENU_LEVEL );

	local info = {
		text 	= PRI_CheckInvVar("close menu"),
		func 			= function()
		end,
		notCheckable 	= 1,
		owner 			= this:GetParent()
	};
	UIDropDownMenu_AddButton( info, UIDROPDOWNMENU_MENU_LEVEL );
	
end

function PRI_CheckInvVar(var)
	if (var) then
		return var;
	else
		return "Enter player name";
	end
end

StaticPopupDialogs["PRI_SetInvited"] = {
	text = "Enter a name of player to be invited:",
	button1 = SAVE,
	button2 = CANCEL,
	OnAccept = function()
		local invitedName = getglobal( this:GetParent():GetName().."EditBox" ):GetText();
		PRI_InvitedName( invitedName );
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	OnCancel = function()
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	EditBoxOnEnterPressed = function()
		local invitedName = this:GetText();
		PRI_InvitedName( invitedName );
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function()
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	OnShow = function()
		if PRI_InvitedNameVar then
			getglobal(this:GetName().."EditBox" ):SetText(PRI_InvitedNameVar);
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox  = true,
	preferredIndex = 3
}

StaticPopupDialogs["PRI_SetInviter"] = {
	text = "Accept invites from:",
	button1 = SAVE,
	button2 = CANCEL,
	OnAccept = function()
		local inviterName = getglobal( this:GetParent():GetName().."EditBox" ):GetText();
		PRI_InviterName( inviterName );
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	OnCancel = function()
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	EditBoxOnEnterPressed = function()
		local inviterName = this:GetText();
		PRI_InviterName( inviterName );
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	OnShow = function()
		if PRI_InviterNameVar then
			getglobal(this:GetName().."EditBox" ):SetText(PRI_InviterNameVar);
		end
	end,
	EditBoxOnEscapePressed = function()
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox  = true,
	preferredIndex = 3
}

StaticPopupDialogs["PRI_SetTimerino"] = {
	text = "Change timer for auto invites:",
	button1 = SAVE,
	button2 = CANCEL,
	OnAccept = function()
		local tim = getglobal( this:GetParent():GetName().."EditBox" ):GetText();
		PRI_SetTimerTo( tim );
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	OnCancel = function()
		getglobal( this:GetParent():GetName().."EditBox" ):SetText("");
	end,
	EditBoxOnEnterPressed = function()
		local tim = this:GetText();
		PRI_SetTimerTo( tim );
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function()
		this:SetText("");
		local parent = this:GetParent();
		parent:Hide();
	end,
	OnShow = function()
		if PRI_Timerino then
			getglobal(this:GetName().."EditBox" ):SetText(PRI_Timerino);
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox  = true,
	preferredIndex = 3
	
}


function PRI_OnClick() 
    local button = arg1
	
	moveX = 0
	if (PartyReInvite_IconFrame:GetLeft() >= (GetScreenWidth() - 200)) then
		moveX = (180 - (GetScreenWidth() - PartyReInvite_IconFrame:GetLeft())) * -1
	end
	
    if IsControlKeyDown() and button == "LeftButton" then
        PRI_TimerCancel();
        return
    end
	
	ToggleDropDownMenu( 1, nil, PRI_DropDownMenu, PartyReInvite_IconFrame, moveX, 0 );
end

--minimap button
local PRI_ButtonRadius = 78;

function PRIButton_UpdatePosition()
	PartyReInvite_IconFrame:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		54 - ( PRI_ButtonRadius * cos( PRI_ButtonPosition ) ),
		( PRI_ButtonRadius * sin( PRI_ButtonPosition ) ) - 55
	);
end

function PRIButton_BeingDragged()
    local xpos,ypos = GetCursorPosition() 
    local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom() 

    xpos = xmin-xpos/UIParent:GetScale()+70 
    ypos = ypos/UIParent:GetScale()-ymin-70 

    PRIButton_SetPosition(math.deg(math.atan2(ypos,xpos)));
end

function PRIButton_SetPosition(v)
    if(v < 0) then
        v = v + 360;
    end

    PRI_ButtonPosition = v;
    PRIButton_UpdatePosition();
end
--end of minimap button

--timer counter frame
function PRI_TimerFramePop()
	-- preventing multiple timer frames to show
	if not PRI_TimerTXT then
	
		PRI_TimerTXT = CreateFrame("Frame", "PRI_TimerFramePop", UIParent)
		
		PRI_TimerTXT:SetWidth(60)
		PRI_TimerTXT:SetHeight(40)
		
		PRI_TimerTXT:SetPoint("TOPLEFT", UIParent, "TOPLEFT", PRI_TimerPosX, PRI_TimerPosY)
		
		PRI_TimerTXT:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = {left = 11, right = 12, top = 12, bottom = 11}
		})
		PRI_TimerTXT:SetMovable(true)
		PRI_TimerTXT:EnableMouse(true)
		PRI_TimerTXT:RegisterForDrag("LeftButton")
		PRI_TimerTXT:SetScript("OnDragStart", function() PRI_TimerTXT:StartMoving() end)
		PRI_TimerTXT:SetScript("OnDragStop", function() PRI_TimerTXT:StopMovingOrSizing() end)
		PRI_TimerTXT:SetScript("OnHide", function() PRI_TimerFrameSetPos() end)
		
		PRI_TimerTXT.text = PRI_TimerTXT:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		PRI_TimerTXT.text:SetPoint("CENTER", PRI_TimerTXT, "CENTER", 0, 0)
		PRI_TimerTXT.text:SetText("test")
		
		local closeBtn = CreateFrame("Button", nil, PRI_TimerTXT, "UIPanelButtonTemplate")
		closeBtn:SetPoint("BOTTOM", 0, -10)
		closeBtn:SetWidth(50)
		closeBtn:SetHeight(20)
		closeBtn:SetText("Now")
		closeBtn:SetScript("OnClick", function() PRI_TimerStop() end)

		function PRI_TimerFrameSetPos()
			PRI_TimerPosX = PRI_TimerTXT:GetLeft();
			PRI_TimerPosY = (GetScreenHeight() - PRI_TimerTXT:GetTop()) * -1;
			PRI_SaveTimerPos(PRI_TimerPosX, PRI_TimerPosY);
		end
		
		function PRI_TimerTXT:SetText(text)
			self.text:SetText(text)
		end
	else
		PRI_TimerTXT:Show()
	end
end
--end of timer counter frame

--settings frame
function PRI_SettingsFramePop()
	-- preventing multiple frames to show
	if not PRI_SettingsTXT then
	
		PRI_SettingsTXT = CreateFrame("Frame", "PRI_SettingsFramePop", UIParent)
		
		PRI_SettingsTXT:SetWidth(300)
		PRI_SettingsTXT:SetHeight(320)
		
		PRI_SettingsTXT:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		
		PRI_SettingsTXT:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = {left = 11, right = 12, top = 12, bottom = 11}
		})
		PRI_SettingsTXT:SetMovable(true)
		PRI_SettingsTXT:EnableMouse(true)
		PRI_SettingsTXT:RegisterForDrag("LeftButton")
		PRI_SettingsTXT:SetScript("OnDragStart", function() PRI_SettingsTXT:StartMoving() end)
		PRI_SettingsTXT:SetScript("OnDragStop", function() PRI_SettingsTXT:StopMovingOrSizing() end)
		
		--Settings labels start
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("CENTER", PRI_SettingsTXT, "TOP", 0, -17)
		PRI_SettingsTXT.text:SetFont("Fonts\\FRIZQT__.TTF",13,"");
		PRI_SettingsTXT.text:SetText("Player RE-Invite settings:")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -47)
		PRI_SettingsTXT.text:SetText("|cffffffffEnable:|r")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("CENTER", PRI_SettingsTXT, "TOP", -12, -72)
		PRI_SettingsTXT.text:SetFont("Fonts\\FRIZQT__.TTF",13,"");
		PRI_SettingsTXT.text:SetText("Timer settings:")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -87)
		PRI_SettingsTXT.text:SetText("|cffffffffSeconds for reinvite:|r")
		
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("CENTER", PRI_SettingsTXT, "TOP", -12, -128)
		PRI_SettingsTXT.text:SetFont("Fonts\\FRIZQT__.TTF",13,"");
		PRI_SettingsTXT.text:SetText("Incoming invites settings:")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -146)
		PRI_SettingsTXT.text:SetText("|cffffffffAuto accept invites:|r")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -171)
		PRI_SettingsTXT.text:SetText("|cffffffffDecline all invites    \n except set player:|r")
		
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("CENTER", PRI_SettingsTXT, "TOP", -12, -200)
		PRI_SettingsTXT.text:SetFont("Fonts\\FRIZQT__.TTF",13,"");
		PRI_SettingsTXT.text:SetText("Player names:")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -218)
		PRI_SettingsTXT.text:SetText("|cffffffffPlayer to invite back:|r")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -236)
		PRI_SettingsTXT.text:SetText("|cffffffffAccept invites from:|r")
		
		
		PRI_SettingsTXT.text = PRI_SettingsTXT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PRI_SettingsTXT.text:SetPoint("RIGHT", PRI_SettingsTXT, "TOP", -12, -256)
		PRI_SettingsTXT.text:SetText("|cffffffffNotify players:|r")
		--Settings labels end
		

		--Settings edit box start
		
		--Invited player
		PRI_SettingsTXT.toInviteEB = CreateFrame("EditBox", nil, PRI_SettingsTXT)
		PRI_SettingsTXT.toInviteEB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -218)
		PRI_SettingsTXT.toInviteEB:SetWidth(100)
		PRI_SettingsTXT.toInviteEB:SetHeight(20)
		PRI_SettingsTXT.toInviteEB:SetFontObject("ChatFontNormal")
		PRI_SettingsTXT.toInviteEB:SetAutoFocus(false)
		PRI_SettingsTXT.toInviteEB:SetMaxLetters(12)
		PRI_SettingsTXT.toInviteEB:SetJustifyH("CENTER")
		PRI_SettingsTXT.toInviteEB:SetText(PRI_InvitedNameVar or "")

		PRI_SettingsTXT.toInviteEB:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		
		PRI_SettingsTXT.toInviteEB:SetBackdropColor(0, 0, 0, 0.5)
		PRI_SettingsTXT.toInviteEB:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

		PRI_SettingsTXT.toInviteEB:SetScript("OnEnterPressed", function()
			this:ClearFocus()
		end)

		PRI_SettingsTXT.toInviteEB:SetScript("OnEscapePressed", function()
			this:ClearFocus()
		end)

		-- Accept invites from
		PRI_SettingsTXT.accInviteEB = CreateFrame("EditBox", nil, PRI_SettingsTXT)
		PRI_SettingsTXT.accInviteEB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -236)
		PRI_SettingsTXT.accInviteEB:SetWidth(100)
		PRI_SettingsTXT.accInviteEB:SetHeight(20)
		PRI_SettingsTXT.accInviteEB:SetFontObject("ChatFontNormal")
		PRI_SettingsTXT.accInviteEB:SetAutoFocus(false)
		PRI_SettingsTXT.accInviteEB:SetMaxLetters(12)
		PRI_SettingsTXT.accInviteEB:SetJustifyH("CENTER")
		PRI_SettingsTXT.accInviteEB:SetText(PRI_InviterNameVar or "")
		
				--to take less lines just snitch visual from previous editbox
		PRI_SettingsTXT.accInviteEB:SetBackdrop(PRI_SettingsTXT.toInviteEB:GetBackdrop())
		
		PRI_SettingsTXT.accInviteEB:SetBackdropColor(0, 0, 0, 0.5)
		PRI_SettingsTXT.accInviteEB:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

		PRI_SettingsTXT.accInviteEB:SetScript("OnEnterPressed", function()
			this:ClearFocus()
		end)
		PRI_SettingsTXT.accInviteEB:SetScript("OnEscapePressed", function()
			this:ClearFocus()
		end)
		
		--changing color on focus
		--[[ meh
		PRI_SettingsTXT.accInviteEB:SetScript("OnEditFocusGained", function()
			this:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
		end)

		PRI_SettingsTXT.accInviteEB:SetScript("OnEditFocusLost", function()
			this:SetBackdropColor(0, 0, 0, 0.5)
		end)
		]]
		
		--Timer seconds
		PRI_SettingsTXT.timerEB = CreateFrame("EditBox", nil, PRI_SettingsTXT)
		PRI_SettingsTXT.timerEB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -87)
		PRI_SettingsTXT.timerEB:SetWidth(100)
		PRI_SettingsTXT.timerEB:SetHeight(20)
		PRI_SettingsTXT.timerEB:SetFontObject("ChatFontNormal")
		PRI_SettingsTXT.timerEB:SetAutoFocus(false)
		PRI_SettingsTXT.timerEB:SetMaxLetters(3)
		PRI_SettingsTXT.timerEB:SetJustifyH("CENTER")
		PRI_SettingsTXT.timerEB:SetText(PRI_Timerino or 0)

		PRI_SettingsTXT.timerEB:SetBackdrop(PRI_SettingsTXT.toInviteEB:GetBackdrop())
		
		PRI_SettingsTXT.timerEB:SetBackdropColor(0, 0, 0, 0.5)
		PRI_SettingsTXT.timerEB:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		
		
		PRI_SettingsTXT.timerEB:SetScript("OnEnterPressed", function()
			this:ClearFocus()
		end)

		PRI_SettingsTXT.timerEB:SetScript("OnEscapePressed", function()
			this:ClearFocus()
		end)
		--end of settings edit boxes
		
		
		--Settings checkboxes
		
		PRI_SettingsTXT.enableCB = CreateFrame("CheckButton", nil, PRI_SettingsTXT, "UICheckButtonTemplate")
		PRI_SettingsTXT.enableCB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -47)
		PRI_SettingsTXT.enableCB:SetChecked(PRI_Enabled)
		
		
		PRI_SettingsTXT.acceptInvCB = CreateFrame("CheckButton", nil, PRI_SettingsTXT, "UICheckButtonTemplate")
		PRI_SettingsTXT.acceptInvCB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -146)
		PRI_SettingsTXT.acceptInvCB:SetChecked(PRI_AccInvites)
		
		
		PRI_SettingsTXT.declineInvCB = CreateFrame("CheckButton", nil, PRI_SettingsTXT, "UICheckButtonTemplate")
		PRI_SettingsTXT.declineInvCB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -171)
		PRI_SettingsTXT.declineInvCB:SetChecked(PRI_DecInvites)
		
		
		PRI_SettingsTXT.notifyCB = CreateFrame("CheckButton", nil, PRI_SettingsTXT, "UICheckButtonTemplate")
		PRI_SettingsTXT.notifyCB:SetPoint("LEFT", PRI_SettingsTXT, "TOP", 0, -256)
		PRI_SettingsTXT.notifyCB:SetChecked(PRI_Notify)
		
		
		--Settings buttons
		local resetTim = CreateFrame("Button", nil, PRI_SettingsTXT, "UIPanelButtonTemplate")
		resetTim:SetPoint("TOP", 0, -97)
		resetTim:SetWidth(90)
		resetTim:SetHeight(20)
		resetTim:SetText("Reset position")
		resetTim:SetScript("OnClick", function() PRI_TimerSetDefaultPos() end)
		
		local closeBtn = CreateFrame("Button", nil, PRI_SettingsTXT, "UIPanelButtonTemplate")
		closeBtn:SetPoint("BOTTOM", 30, 10)
		closeBtn:SetWidth(50)
		closeBtn:SetHeight(20)
		closeBtn:SetText("Cancel")
		closeBtn:SetScript("OnClick", function() PRI_SettingsTXT:Hide() end)
		
		local saveBtn = CreateFrame("Button", nil, PRI_SettingsTXT, "UIPanelButtonTemplate")
		saveBtn:SetPoint("BOTTOM", -30, 10)
		saveBtn:SetWidth(50)
		saveBtn:SetHeight(20)
		saveBtn:SetText("Save")
		saveBtn:SetScript("OnClick", function() PRI_SaveSettings() end)
		
		function PRI_SettingsTXT:SetText(text)
			self.text:SetText(text)
		end
	else
		PRI_SettingsTXT.toInviteEB:SetText(PRI_InvitedNameVar or "")
		PRI_SettingsTXT.accInviteEB:SetText(PRI_InviterNameVar or "")
		PRI_SettingsTXT.timerEB:SetText(PRI_Timerino or 0)
		PRI_SettingsTXT.enableCB:SetChecked(PRI_Enabled)
		PRI_SettingsTXT.acceptInvCB:SetChecked(PRI_AccInvites)
		PRI_SettingsTXT.declineInvCB:SetChecked(PRI_DecInvites)
		PRI_SettingsTXT.declineInvCB:SetChecked(PRI_Notify)
		PRI_SettingsTXT:Show()
	end
	
	function PRI_SaveSettings()
		if not (PRI_SettingsTXT.enableCB:GetChecked() == PRI_Enabled) then
			PRI_Enabler(PRI_SettingsTXT.enableCB:GetChecked())
		end
		
		if not (PRI_SettingsTXT.timerEB:GetText() == PRI_Timerino) then
			PRI_SetTimerTo(PRI_SettingsTXT.timerEB:GetText())
		end
		
		if not (PRI_SettingsTXT.acceptInvCB:GetChecked() == PRI_AccInvites) then
			PRI_EnablerAccept(PRI_SettingsTXT.acceptInvCB:GetChecked())
		end
		
		if not (PRI_SettingsTXT.declineInvCB:GetChecked() == PRI_DecInvites) then
			PRI_EnablerDecline(PRI_SettingsTXT.declineInvCB:GetChecked())
		end
		
		if not (PRI_SettingsTXT.notifyCB:GetChecked() == PRI_Notify) then
			PRI_NotifyFunc(PRI_SettingsTXT.notifyCB:GetChecked())
		end

		if not (PRI_SettingsTXT.toInviteEB:GetText() == PRI_InvitedNameVar) then
			PRI_InvitedName(PRI_SettingsTXT.toInviteEB:GetText())
		end
		
		if not (PRI_SettingsTXT.accInviteEB:GetText() == PRI_InviterNameVar) then
			PRI_InviterName(PRI_SettingsTXT.accInviteEB:GetText())
		end
		
		PRI_SettingsTXT:Hide()
	end
	
end
--end of settings frame
