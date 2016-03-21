global Pankov_IESfromCaustic_Fltr
global IESfromCaustic_main_rollout
global IESfromCaustic_webcheck_rollout

if Pankov_IESfromCaustic_Fltr != undefined then closeRolloutFloater Pankov_IESfromCaustic_Fltr

Pankov_IESfromCaustic_Fltr = newRolloutFloater "IES from caustics generator" 315 440

--( Functions
fn resizeFloater = 
(
	local h=50
	try(
		if Pankov_IESfromCaustic_Fltr.rollouts[1].open then h+=80
		if Pankov_IESfromCaustic_Fltr.rollouts[2].open then h+=310
		Pankov_IESfromCaustic_Fltr.size = [Pankov_IESfromCaustic_Fltr.size[1],h]
	) catch ()
)


--) End Functions

rollout IESfromCaustic_main_rollout "Script"
(
	group "Load Scenes" (
		button LoadRenderCausticBtn "Render Caustic scene" across:2
		button LoadRenderTestBtn "Render Test IES scene"
	)
	group "MetaData" (
		editText ManufacTxt "Manufacturer" text:"noname"
		editText LumcatTxt "Model" text:"noname"
		editText LampTxt "Lamp Type" text:"Galogen"
		spinner PowerSpin "Power consumption (Watts)" range:[0.1,1000,40] type:#float
		spinner LMSpin "Luminous Power (lm)" range:[0.1,1000,10] type:#float
		spinner SizeSpin "Size (in mm)" range:[0,1000,10] type:#float
	)
	group "Resolution" (
		spinner RndrWidthSpin "Render Width" range:[50,722,361] type:#integer
		spinner RndrHeightSpin "Render Height" range:[25,362,181] type:#integer
	)
	button createBtn "Create IES to..."
	
	on LoadRenderCausticBtn pressed do (
		loadMaxFile ((getDir #userScripts)+"\\IESfromCaustics\\RenderCaustics_max2012.max") useFileUnits:true
	)

	on LoadRenderTestBtn pressed do (
		loadMaxFile ((getDir #userScripts)+"\\IESfromCaustics\\RenderCaustics_test_max2012.max") useFileUnits:true
	)
	
	on RndrWidthSpin changed val do (
		RndrHeightSpin.value = val/1.994475138121547
	)

	on RndrHeightSpin changed val do (
		RndrWidthSpin.value = val*1.994475138121547
	)
	
	on createBtn pressed do (
		fname = ""
		if ManufacTxt.text != "noname" then fName = fName+ManufacTxt.text
		if LumcatTxt.text != "noname" then fName = fName+"-"+LumcatTxt.text
		if fname!="" then fname = fname + ".ies"
		try (newIES = createFile (getSaveFileName caption:"Choose path to save the model" filename:(if fname!="" then fname else "") initialDir:maxfilepath types:"IES File|*.ies|All|*.*")
			renderheight = RndrHeightSpin.value
			renderwidth = RndrWidthSpin.value
			bh = renderheight
			bw = renderwidth
			cbitmap = bitmap bw bh gamma:1
			render camera:cameras[1] to:cbitmap outputHDRbitmap:true progressbar:true
			barray = #()
			for line = 1 to bh do barray[line] = getPixels cbitmap [0,(line-1)] bw
			ies_lines = #("")
			for pix_w = 1 to bw do (
				ies_lines[pix_w]=(floor(barray[bh][pix_w].red*10)/10) as string
				for pix_h = 2 to bh do (
					ies_lines[pix_w]= ies_lines[pix_w]+" "+((floor(barray[bh-pix_h+1][pix_w].red*10)/10) as string)
				)
			)
	
			-- save file
			--newIES = openFile "C:\\temp\\test1.ies" mode:"r+"
			step_w = 180.0/(bh-1)
			step_h = 360.0/(bw-1)
			local last
			format ("IESNA:LM-63-1995\n[DATA] "+(substring localtime 1 ((findstring localtime " ") - 1))+
				"\n[MANUFAC] "+ ManufacTxt.text +
				"\n[LUMCAT] " + LumcatTxt.text + 
				"\n[LAMP] " + LampTxt.text +
				"\nTILT=NONE\n"+
				"1 " + (LMSpin.value as string) + " 1 "+(bh as string) +" "+ (bw as string) +" 1 2 -"+((SizeSpin.value/1000) as string)+" 0 0\n"+
				"1 1 "+(PowerSpin.value as string)+"\n") to:newIES
			
			for i = 0 to 180 by step_w do (last = i; format (i as string + " ") to:newIES)
			if last<180 then (format "180" to:newIES)
			format "\n" to:newIES

			for i = 0 to 360 by step_h do (last = i; format (i as string + " ") to:newIES)
			if last<360 then (format "360" to:newIES)
			format "\n" to:newIES
			--for i = 0 to bw-1 do format (i as string + " ") to:newIES
			--format "\n" to:newIES
			for i = 1 to bw do format (ies_lines[i] + "\n") to:newIES
			close newIES
			messagebox "File write success! :)"
		)catch(messagebox "Operation Canceled")
	)
	
	on IESfromCaustic_main_rollout rolledUp state do ( 
		resizeFloater()
	)
	
	on IESfromCaustic_main_rollout close do undo off 
	(
		RollPos = Pankov_IESfromCaustic_Fltr.pos
		setIniSetting (getMaxINIFile()) "IESfromCaustic_Settings" "WindowPos" (RollPos as string)
	)
	
	on IESfromCaustic_main_rollout open do undo off 
	(
		try(t=trackviewnodes;
			n=t[#Anim_Layer_Control_Manager];	deleteTrackViewController t n.controller;
			n=t[#Max_MotionClip_Manager];deleteTrackViewController t n.controller;
			n=t[#Retimer_Manager];deleteTrackViewController t n.controller;
			gc();
		)catch()
		RollPos = getIniSetting (getMaxINIFile()) "IESfromCaustic_Settings" "WindowPos"
		if RollPos != "" and RollPos != undefined do (
			if not keyboard.escPressed do Pankov_IESfromCaustic_Fltr.pos = (execute RollPos)
		)
	)
)
	
rollout IESfromCaustic_webcheck_rollout "About" 
(
--timer tm interval:100 active:true
dotNetControl wb "System.Windows.Forms.WebBrowser" width:315 height:113 pos:[0,0] 

	on IESfromCaustic_webcheck_rollout open do
	(
		Padding 
		wb.ScrollBarsEnabled =false
		wb.url = dotNetObject "System.Uri" ((getDir #userScripts)+"\\IESfromCaustics\\http\\scriptlogo.htm")
		wb.Left = -11
		wb.Top  = -14
		--wb.AllowNavigation = false
		IESfromCaustic_webcheck_rollout.height=80
	)

	on IESfromCaustic_webcheck_rollout rolledUp state do ( 
		resizeFloater()
	)
	
)

addRollout IESfromCaustic_webcheck_rollout Pankov_IESfromCaustic_Fltr rolledUp:false
addRollout IESfromCaustic_main_rollout Pankov_IESfromCaustic_Fltr rolledUp:false