global Pankov_IESfromCaustic_Fltr
global IESfromCaustic_version = "1.1b"
global IESfromCaustic_main_rollout
global IESfromCaustic_webcheck_rollout

if Pankov_IESfromCaustic_Fltr != undefined then closeRolloutFloater Pankov_IESfromCaustic_Fltr

Pankov_IESfromCaustic_Fltr = newRolloutFloater "IES from caustics generator" 315 440

--( Functions
fn resizeFloater = 
(
	local h=Pankov_IESfromCaustic_Fltr.rollouts.count * 30 
	for i in 1 to Pankov_IESfromCaustic_Fltr.rollouts.count do (
		if Pankov_IESfromCaustic_Fltr.rollouts[i].open then h+=Pankov_IESfromCaustic_Fltr.rollouts[i].height)
	Pankov_IESfromCaustic_Fltr.size = [Pankov_IESfromCaustic_Fltr.size[1],h]
)

--( -- Settings INI Functions
struct controlData (ctrl, data)--, enabled, visible)

fn getControlData control = (
	case (classof control) of (
		SpinnerControl: controlData ctrl:control data:#(#value, control.value) --enabled:control.enabled visible:control.visible
		CheckBoxControl: controlData ctrl:control data:#(#state, control.state) --enabled:control.enabled visible:control.visible
		CheckButtonControl: controlData ctrl:control data:#(#state, control.state) --enabled:control.enabled visible:control.visible
		RadioControl: controlData ctrl:control data:#(#state, control.state) --enabled:control.enabled visible:control.visible
		editTextControl: controlData ctrl:control data:#(#text,"\\\""+control.text+"\\\"") --enabled:control.enabled visible:control.visible
		SliderControl: controlData ctrl:control data:#(#range, control.range) --enabled:control.enabled visible:control.visible
	)
)

fn rolloutDefsToINI roll fname exclude = (
	local ctrlName = ""
	for c in (execute (roll+".controls")) do (
		ctrlName = (substring (c as string) ((findstring (c as string) ":")+1) 100)
		if (findItem exclude ctrlName)==0 then (
			a = getControlData c
			if a != undefined then setIniSetting fname roll ctrlName (a.data as string)
		)
	)
)

fn saveDefaultsToINI fname = (
	setIniSetting fname "IESfromCaustic_Settings" "Version" IESfromCaustic_version
	rolloutDefsToINI "IESfromCaustic_main_rollout" fname #()
)

fn rolloutDefsFromINI roll fname exclude = (
	local data
	for ctrl in (getIniSetting fname (roll)) where ((finditem exclude ctrl)==0) do (
		data = execute (getIniSetting fname roll ctrl)
		if data!="" then execute (roll+"."+ctrl+"."+(data[1] as string)+"="+(data[2] as string))
	)
)

fn loadDefaultsFromINI fname = (
	local data
	local str
	local exec = true
	if doesFileExist fname then (
		data = getIniSetting fname "IESfromCaustic_Settings" "Version" 
		if data!=IESfromCaustic_version then (
			if data=="" then data="old"
			if not (querybox ("Current version is "+IESfromCaustic_version+"\nINI file version is "+data+"\n\nDo you still want to load this INI file?") title:"Incompatible version of ini file" ) then exec = false		--"Current version is "+cgportVersion+"\nINI file version is "+data+"\n\nDo you still want to load this INI file?") title:"Incompatible version of ini file"
		)
		if exec then (
			rolloutDefsFromINI "IESfromCaustic_main_rollout" fname #()
		)
	)
) 


--) -- end Settings INI Functions

fn RenderCaustics = (
	local p
	local hided = false
	if renderscenedialog.isOpen() then (p = true; renderscenedialog.close()) else p = false
	renderheight = IESfromCaustic_main_rollout.RndrHeightSpin.value
	renderwidth = IESfromCaustic_main_rollout.RndrWidthSpin.value
	local bmap = bitmap renderwidth renderheight gamma:1
		
	renderers.current.caustics_mode = 0
	if meditmaterials[24].name == "Caustics_Glass" then (
		meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
		if IESfromCaustic_main_rollout.chkLeaveGlassShadows.checked then (
			meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 0   -- turn opacity OFF
		)else(
			meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 100   -- turn opacity ON
		)
	)
	render camera:cameras[1] outputHDRbitmap:true progressbar:true vfb:false --(not chkRenderOnlyCaustics.checked)
	
	renderers.current.saveCausticsPhotonMap ((getDir #userScripts)+"\\IESfromCaustics\\caustics_preview.vrpmap")
	renderers.current.caustics_mode = 1
	renderers.current.caustics_loadFileName = ((getDir #userScripts)+"\\IESfromCaustics\\caustics_preview.vrpmap")
	if IESfromCaustic_main_rollout.chkRenderOnlyCaustics.checked then (	hide $Caustic_Light.children; hided = true)
	if meditmaterials[24].name == "Caustics_Glass" then meditmaterials[24].basemtl.texmap_opacity_multiplier = 100 -- turn direct visibility OFF (opacity ON)
	render camera:cameras[1] to:bmap outputHDRbitmap:true progressbar:true
	
	renderers.current.caustics_mode = 0
	--IESfromCaustic_main_rollout.chkUsePrecalcCaustics.checked = false
	if meditmaterials[24].name == "Caustics_Glass" then meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
	if hided then unhide $Caustic_Light.children
	if meditmaterials[24].name == "Caustics_Glass" then (
		meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
		meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 0   -- turn opacity OFF
	)
	if p then (renderscenedialog.open())
	return bmap
)

--) End Functions


rollout IESfromCaustic_main_rollout "Script"
(	
	local LigthMultController=bezier_float()
	local GlassIorController=bezier_float()
	local SphereRadiusController=bezier_float()
	local RecieveCausticsMultController=bezier_float()
	local ReflectController=bezier_float()
	
	group "Settings" (
		checkbox chkSaveDefaults "Save last settings on exit" checked:true across:2
		button btnResetToDefaults "Reset to defaults"
	)
	group "Step1 - Load Scenes (vRay)" (
		button LoadRenderCausticBtn "Load Render Caustic scene" across:2
		button btnDeleteExample "Delete example obj"
		label lbl1 "After loading the scene, merge your fixtures"
	)
	group "Step2 - Turn the scene" (
		label lblStatus "Status: " align:#left
		--label lbl2 "-------- Fast scene settings: --------"
		spinner spnSphereRadius "Sphere Radius" range:[1,5000,2] controller:SphereRadiusController --offset:[0,5]
		button btnAssignGlassMat "Glass mat to selected" tooltip:"Glass material to the crystals" across:2
		button btnAssignChromeMat "Chrome mat selected" tooltip:"Chrome material to reflector"
		spinner spnGlassIOR "Glass IOR" range:[1,10,2] controller:GlassIorController offset:[0,5] across:2 --align:#left
		spinner spnReflectIntensity "Reflector (%)" range:[0,100,100] controller:ReflectController offset:[0,5] align:#right --across:2
		spinner spnLightMut "Light multiplier" range:[0,10000,50] controller:LigthMultController across:2
		spinner spnCausticsMut "Caustics mult" range:[1,100,1] controller:RecieveCausticsMultController
		-- checkbox chkCausics "Turn on caustics" align:#right
		checkbox chkLeaveGlassShadows "Leave glass shadows" align:#center checked:false across:2 offset:[0,5]
		checkbox chkRenderOnlyCaustics "Render only caustic" align:#center tooltip:"Without direct lightning"  checked:false offset:[0,5]
		button btnPreviewRender "PREVIEW RENDER" --tooltip:"Change caustics samples to 2500"
	)
	group "Step 3 - MetaData" (
		editText ManufacTxt "Manufacturer" text:"noname" fieldWidth:205 align:#right
		editText LumcatTxt "Model" text:"noname" fieldWidth:205 align:#right
		editText LampTxt "Lamp Type" text:"Galogen" fieldWidth:205 align:#right
		spinner PowerSpin "Power consumption (Watts)" range:[0.1,1000,40] type:#float
		spinner LMSpin "Luminous Power (lm)" range:[0.1,1000,10] type:#float
		spinner SizeSpin "Size (in mm)" range:[0,1000,10] type:#float
	)
	group "Step 4 - Resolution" (
		spinner RndrWidthSpin "Render Width" range:[50,721,361] type:#integer
		spinner RndrHeightSpin "Render Height" range:[25,361,181] type:#integer
	)
	--button btnLoadFinalSet "Load Final settings" tooltip:"Change caustics samples to 7500"
	--button btnSaveCausctics "[ Step 5 - Pre Calculate Caustics ]" tooltip:"[ optional ] and save to temp folder and turn to saved map" across:2 align:#left
	--checkbox chkDeletCausticsOnExit "Delete file on exit" offset:[40,5] checked:true
	group "Final Step" (
		-- checkbox chkUsePrecalcCaustics "Use precalc caustics" align:#center checked:true
		button createBtn "Step 5 - Create IES to.."
	)
	group "Testing" (
		button LoadRenderTestBtn "Step 6 - Load scene to test IES"
	)

	fn AssignControllers = 
	(
		try (
			SphereRadiusController.value = $IES_Caustics_Catcher.radius
			$IES_Caustics_Catcher.radius.controller=SphereRadiusController 
			spnSphereRadius.enabled = true
		)catch(
			spnSphereRadius.enabled = false
		)
		
		try (
			LigthMultController.value = $VRayLight_Prev.multiplier
			$VRayLight_Prev.multiplier.controller=LigthMultController 
			$VRayLight_Final.multiplier.controller=LigthMultController
			spnLightMut.enabled = true
		)catch(
			spnLightMut.enabled = false
		)
		
		if meditmaterials[24].name == "Caustics_Glass" then (
			try (
				GlassIorController.value = meditmaterials[24].basemtl.refraction_ior
				meditmaterials[24].basemtl.refraction_ior.controller = GlassIorController
				spnGlassIOR.enabled = true
			)catch()
		)else(
			spnGlassIOR.enabled = false
		)
		
		if meditmaterials[23].name == "White Sphere" then (
			try (
				RecieveCausticsMultController.value = meditmaterials[23].causticsMult
				meditmaterials[23].causticsMult.controller = RecieveCausticsMultController
				spnCausticsMut.enabled = true
			)catch()
		)else(
			spnCausticsMut.enabled = false
		)
		
		if meditmaterials[22].name == "chrome" then (
			try (
				ReflectController.value = meditmaterials[22].texmap_reflection_multiplier
				meditmaterials[22].texmap_reflection_multiplier.controller = ReflectController
				spnReflectIntensity.enabled = true
			)catch()
		)else(
			spnReflectIntensity.enabled = false
		)
		
	)
		
	on btnResetToDefaults pressed do (
		RollPos = Pankov_IESfromCaustic_Fltr.pos
		if Pankov_IESfromCaustic_Fltr!=undefined then closeRolloutFloater Pankov_IESfromCaustic_Fltr
		deletefile ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos" (RollPos as string)
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "Version" IESfromCaustic_version
		macros.run "#PankovScripts" "Pankov_IESfromCaustic"
	)
	
	on LoadRenderCausticBtn pressed do (
		loadMaxFile ((getDir #userScripts)+"\\IESfromCaustics\\RenderCaustics_max2012.max") useFileUnits:true
		AssignControllers ()
	)

	on btnDeleteExample pressed do (
		delete $Sample_fixture
	)
	
	on LoadRenderTestBtn pressed do (
		loadMaxFile ((getDir #userScripts)+"\\IESfromCaustics\\RenderCaustics_test_max2012.max") useFileUnits:true
	)
	
	on btnPreviewRender pressed do (
		try (
			$VRayLight_Final.on = false
			$VRayLight_Prev.on  = true
			lblStatus.caption = "Status: Draft (1500 caustic samples)"
			
		)catch(
			lblStatus.Caption = "Status: Error. No Lights to be changed. Goto Step1"
		)
		renderCaustics()
	)

	fn LoadFinalSet = (
		try (
			$VRayLight_Final.on = true
			$VRayLight_Prev.on  = false
			lblStatus.caption = "Status: Final (7000 caustic samples)"
		)catch(
			lblStatus.Caption = "Status: Error. No Lights to be changed. Goto Step1"
		)
	)
	
	on btnAssignGlassMat pressed do (
		if meditmaterials[24].name == "Caustics_Glass" then (
			if selection.count>0 then (
				local geomObj = for obj in selection where (
					(superclassof obj == GeometryClass OR superclassof obj == shape) AND obj.name != "IES_Caustics_Catcher"
				) collect obj
				for obj in geomObj do obj.material = meditmaterials[24]
				)else( messagebox "Please select glass elements" )
		) else ( messagebox "Nothing has been changed. Please load template scene in Step 1" )
	)

	on btnAssignChromeMat pressed do (
		if meditmaterials[22].name == "chrome" then (
			if selection.count>0 then (
				local geomObj = for obj in selection where (
					(superclassof obj == GeometryClass OR superclassof obj == shape) AND obj.name != "IES_Caustics_Catcher"
				) collect obj
				for obj in geomObj do obj.material = meditmaterials[22]
				)else( messagebox "Please select reflector and chrome elements" )
		) else ( messagebox "Nothing has been changed. Please load template scene in Step 1" )
	)
	
	/*on chkCausics changed state do (
		local p
		if renderscenedialog.isOpen() then (p = true; renderscenedialog.close()) else p = false
		renderers.current.caustics_on = state
		if p then (renderscenedialog.open())
	)*/
	
	on RndrWidthSpin changed val do (
		RndrHeightSpin.value = val/1.994475138121547
	)

	on RndrHeightSpin changed val do (
		RndrWidthSpin.value = val*1.994475138121547
	)
	
	/*
	on chkUsePrecalcCaustics changed state do (
		local fname = ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap")
		local exec = true
		if state then (
			if doesfileexist fname then (
				if ((getLocalTime())[4] as string) != (filterstring (getFileModDate fname) "/")[2] then (
					exec = querybox "The file was created in another day. May be that is old file and need to create a new one.\nDo you want to use old file?"
				)
				if exec then (
					renderers.current.caustics_mode = 1
					renderers.current.caustics_loadFileName = fname
				) else (chkUsePrecalcCaustics.state = false)
			) else (
				messagebox ("File does not exist:\n"+fname)
				chkUsePrecalcCaustics.state = false
			)
		) else (
			renderers.current.caustics_mode = 0
		)
	)
	*/
	
	/*
	on btnSaveCausctics pressed do (
		if renderers.current.caustics_on then (
			LoadFinalSet()
			renderers.current.caustics_mode = 0
			render camera:cameras[1] outputHDRbitmap:true progressbar:true
			renderers.current.saveCausticsPhotonMap ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap")
			renderers.current.caustics_mode = 1
			renderers.current.caustics_loadFileName = ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap")
			chkUsePrecalcCaustics.state = true
		)
	)	
	*/
	
	on createBtn pressed do (
		local fname = ""
		if ManufacTxt.text != "noname" then fName = fName+ManufacTxt.text
		if LumcatTxt.text != "noname" then fName = fName+"-"+LumcatTxt.text
		if fname!="" then fname = fname + ".ies"
		try (newIES = createFile (getSaveFileName caption:"Choose path to save the model" filename:(if fname!="" then fname else "") initialDir:maxfilepath types:"IES File|*.ies|All|*.*")
			renderheight = RndrHeightSpin.value
			renderwidth = RndrWidthSpin.value
			bh = renderheight
			bw = renderwidth
			cbitmap = bitmap bw bh gamma:1
			LoadFinalSet()
			
			cbitmap = renderCaustics()

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
			
			for i = 0.0 to 180.0 by step_w do (last = i; format (i as string + " ") to:newIES)
			--if last<180 then (format "180.0" to:newIES)
			format "\n" to:newIES

			for i = 0.0 to 360.0 by step_h do (last = i; format (i as string + " ") to:newIES)
			--if last<360 then (format "360.0" to:newIES)
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
		--if chkDeletCausticsOnExit.state then (
			if doesfileexist ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap") then 
				--if querybox "Really delete created caustics file?" then (
					deletefile ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap")
					--chkUsePrecalcCaustics.checked = false
				--)
			if doesfileexist ((getDir #userScripts)+"\\IESfromCaustics\\caustics_preview.vrpmap") then 
				deletefile ((getDir #userScripts)+"\\IESfromCaustics\\caustics_preview.vrpmap")
		--)
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos" (RollPos as string)
		if chkSaveDefaults.checked then (
			saveDefaultsToINI ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		) else (
			setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_main_rollout" "chkSaveDefaults" ("#(#state, "+(chkSaveDefaults.checked as string)+")")
		)
	)
	
	on IESfromCaustic_main_rollout open do undo off 
	(
		try(t=trackviewnodes;
			n=t[#Anim_Layer_Control_Manager];	deleteTrackViewController t n.controller;
			n=t[#Max_MotionClip_Manager];deleteTrackViewController t n.controller;
			n=t[#Retimer_Manager];deleteTrackViewController t n.controller;
			gc();
		)catch()
		loadDefaultsFromINI ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		RollPos = getIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos"
		if RollPos != "" and RollPos != undefined do (
			if not keyboard.escPressed do Pankov_IESfromCaustic_Fltr.pos = (execute RollPos)
		)
		
		-- chkCausics.state = renderers.current.caustics_on
		-- Assign Controllers
		AssignControllers ()
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
resizeFloater()
