global Pankov_IESfromCaustic_Fltr
global IESfromCaustics_version = "1.2b"
global IESfromCaustics_main_rollout
global IESfromCaustics_webcheck_rollout
global IESfromCaustics_TmpPath = (getDir #userScripts)+"\\IESfromCaustics\\"

if Pankov_IESfromCaustic_Fltr != undefined then closeRolloutFloater Pankov_IESfromCaustic_Fltr

Pankov_IESfromCaustic_Fltr = newRolloutFloater "IES from caustics generator" 315 440

--( Functions
--(-- Interface functions
fn resizeFloater = 
(
	local h=Pankov_IESfromCaustic_Fltr.rollouts.count * 30 
	for i in 1 to Pankov_IESfromCaustic_Fltr.rollouts.count do (
		if Pankov_IESfromCaustic_Fltr.rollouts[i].open then h+=Pankov_IESfromCaustic_Fltr.rollouts[i].height)
	Pankov_IESfromCaustic_Fltr.size = [Pankov_IESfromCaustic_Fltr.size[1],h]
)

fn wrapString str = (
	local widthCaracters = 37
	if str.count>widthCaracters then (return (substring str 1 (widthCaracters/3-3)) + "..." + (substring str (str.count - widthCaracters/3*2+1) (widthCaracters/3*2+3)))
		else (return str)
)
--)-- Interface functions

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
	setIniSetting fname "IESfromCaustic_Settings" "Version" IESfromCaustics_version
	setIniSetting fname "IESfromCaustic_Settings" "tempPath" IESfromCaustics_TmpPath
	rolloutDefsToINI "IESfromCaustics_main_rollout" fname #()
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
		if data!=IESfromCaustics_version then (
			if data=="" then data="old"
			if not (querybox ("Current version is "+IESfromCaustics_version+"\nINI file version is "+data+"\n\nDo you still want to load this INI file?") title:"Incompatible version of ini file" ) then exec = false		--"Current version is "+cgportVersion+"\nINI file version is "+data+"\n\nDo you still want to load this INI file?") title:"Incompatible version of ini file"
		)
		data = getIniSetting fname "IESfromCaustic_Settings" "tempPath"
		if doesfileexist data then (
			IESfromCaustics_TmpPath = data
			IESfromCaustics_settings_rollout.btnOpenTmpPath.caption = wrapString IESfromCaustics_TmpPath
		)else(messagebox ("Path doesn't exist \n"+data+"Defaulsts used"))
		if exec then (
			rolloutDefsFromINI "IESfromCaustics_main_rollout" fname #()
		)
	)
) 

fn slct m = (
	local s
	local mat
	case of (
		((m == "chrome") and (meditmaterials[22].name=="chrome")) : mat = meditmaterials[22]
		((m == "sphere") and (meditmaterials[23].name=="White Sphere")) : mat = meditmaterials[23]
		((m == "glass") and (meditmaterials[24].name=="Caustics_Glass")) : mat = meditmaterials[24]
		default: return undefined
	)
	s = for obj in $* where obj.material == mat collect obj
	return s
)

--) -- end Settings INI Functions

fn RenderCaustics = (
	local p
	local hided = false
	local chromeObj = #()
	if renderscenedialog.isOpen() then (p = true; renderscenedialog.close()) else p = false
	renderheight = IESfromCaustics_main_rollout.RndrHeightSpin.value
	renderwidth = IESfromCaustics_main_rollout.RndrWidthSpin.value
	local bmap = bitmap renderwidth renderheight gamma:1
		
	renderers.current.caustics_mode = 0
	if meditmaterials[24].name == "Caustics_Glass" then (
		meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
		if IESfromCaustics_main_rollout.chkLeaveGlassShadows.checked then (
			meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 0   -- turn opacity OFF
		)else(
			meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 100   -- turn opacity ON
		)
	)
	renderers.current.options_dontRenderImage = true
	render camera:cameras[1] outputHDRbitmap:true progressbar:true vfb:false --(not chkRenderOnlyCaustics.checked)
	
	renderers.current.saveCausticsPhotonMap (IESfromCaustics_TmpPath+"last_IEScaustics_calc.vrpmap")
	renderers.current.caustics_mode = 1
	renderers.current.caustics_loadFileName = (IESfromCaustics_TmpPath+"last_IEScaustics_calc.vrpmap")
	if IESfromCaustics_main_rollout.chkRenderOnlyCaustics.checked then (hide $Caustic_Light.children; hided = true)
	if meditmaterials[24].name == "Caustics_Glass" then meditmaterials[24].basemtl.texmap_opacity_multiplier = 100 -- turn direct visibility OFF (opacity ON)
	if (meditmaterials[22].name == "chrome") AND (meditmaterials[23].name == "White Sphere") then (
		chromeObj = slct "chrome"
		for obj in chromeObj do obj.material = meditmaterials[23]
	)
	renderers.current.options_dontRenderImage = false
	render camera:cameras[1] to:bmap outputHDRbitmap:true progressbar:true
	
	if (meditmaterials[22].name == "chrome") AND (meditmaterials[23].name == "White Sphere") then for obj in chromeObj do obj.material = meditmaterials[22]
	renderers.current.caustics_mode = 0
	--IESfromCaustics_main_rollout.chkUsePrecalcCaustics.checked = false
	if meditmaterials[24].name == "Caustics_Glass" then meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
	if hided then unhide $Caustic_Light.children
	if meditmaterials[24].name == "Caustics_Glass" then (
		meditmaterials[24].basemtl.texmap_opacity_multiplier = 0 -- turn direct visibility ON (opacity OFF)
		meditmaterials[24].shadowMtl.texmap_opacity_multiplier = 0   -- turn opacity OFF
	)
	if p then (renderscenedialog.open())
	return bmap
)

fn FormatTime msec = (
	--h = (msec/3600000) as integer
	--ss = msec - h * 3600000
	--m = (ss/60000) as integer
	--ss -= m * 60000
	m = (msec/60000) as integer
	s = ((msec - m * 60000)/1000) as integer
	--ss = (ss - s*1000) as string
	return ((m as string) + " min. " + (s as string) + " sec.")  -- + "." + ss)
)
--) End Functions

rollout IESfromCaustics_settings_rollout "Settings"
(	
	checkbox chkSaveDefaults "Save last settings on exit" checked:true across:2
	button btnResetToDefaults "Reset to defaults" align:#right
	button btnOpenTmpPath "..userScripts\\IESfromCaustics\\" tooltip:"Open temp path" width:190 align:#left across:2 --offset:[0,5]
	button btnSelTmpPath "Sel temp path" align:#right --offset:[0,5]

	on btnOpenTmpPath pressed do (
		ShellLaunch "explorer.exe" ("\""+IESfromCaustics_TmpPath+"\"")	
	)

	on btnSelTmpPath pressed do (
		local p = getSavePath caption:"Choose the temp folder" initialDir:IESfromCaustics_TmpPath 
		if p != undefined then IESfromCaustics_TmpPath=p+"\\"
		btnOpenTmpPath.caption = wrapString IESfromCaustics_TmpPath
	)
	
	on btnResetToDefaults pressed do (
		RollPos = Pankov_IESfromCaustic_Fltr.pos
		if Pankov_IESfromCaustic_Fltr!=undefined then closeRolloutFloater Pankov_IESfromCaustic_Fltr
		deletefile ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos" (RollPos as string)
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "Version" IESfromCaustics_version
		macros.run "#PankovScripts" "Pankov_IESfromCaustic"
	)

	on IESfromCaustics_settings_rollout rolledUp state do ( 
		resizeFloater()
	)

)
	
rollout IESfromCaustics_main_rollout "Script"
(	
	local LigthMultController=bezier_float()
	local LightRadiusController=bezier_float()
	local GlassIorController=bezier_float()
	local SphereRadiusController=bezier_float()
	local RecieveCausticsMultController=bezier_float()
	local ReflectController=bezier_float()
	
	group "Step1 - Load Scenes (vRay)" (
		button LoadRenderCausticBtn "Load Render Caustic scene" across:2 align:#left
		button btnDeleteExample "Delete example obj" align:#right
		label lbl1 "After loading the scene, merge your fixtures"
	)
	group "Step2 - Turn the scene" (
		label lblStatus "Status: " align:#left
		spinner spnLightRadius "Light Radius" range:[0.1,10,2] controller:LightRadiusController tooltip:"Use values higher 1.5 and lower 0.2" --offset:[0,5]
		button btnAssignGlassMat "Glass mat to selected" tooltip:"Glass material to the crystals" across:2
		button btnAssignChromeMat "Chrome mat selected" tooltip:"Chrome material to reflector"
		spinner spnGlassIOR "Glass IOR" range:[1,10,2] controller:GlassIorController offset:[0,5] across:2 --align:#left
		spinner spnReflectIntensity "Reflector (%)" range:[0,100,100] controller:ReflectController offset:[0,5] align:#right --across:2
		spinner spnLightMut "Light multiplier" range:[0,10000,50] controller:LigthMultController across:2
		spinner spnCausticsMut "Caustics mult" range:[0.01,100,1] controller:RecieveCausticsMultController
		checkbox chkLeaveGlassShadows "Leave glass shadows" align:#center checked:true across:2 offset:[0,5]
		checkbox chkRenderOnlyCaustics "Render only caustic" align:#center tooltip:"Without direct lightning"  checked:false offset:[0,5]
		button btnPreviewRender "PREVIEW RENDER" --tooltip:"Change caustics samples to 2500"
	)
	group "Step 3 - MetaData" (
		editText ManufacTxt "Manufacturer" text:"noname" fieldWidth:205 align:#right
		editText LumcatTxt "Model" text:"noname" fieldWidth:205 align:#right
		editText LampTxt "Lamp Type" text:"Galogen" fieldWidth:205 align:#right
		spinner PowerSpin "Power consumption (Watts)" range:[0.1,1000,40] type:#float
		spinner LMSpin "Luminous Power (lm)" range:[0.1,1000,350] type:#float
		spinner SizeSpin "Size (in mm)" range:[0,1000,10] type:#float
	)
	group "Step 4 - Resolution" (
		spinner RndrWidthSpin "Render Width" range:[50,721,361] type:#integer
		spinner RndrHeightSpin "Render Height" range:[25,361,181] type:#integer
	)
	group "Final Step" (
		button createBtn "Step 5 - Create IES to.."
	)
	group "Testing" (
		button LoadRenderTestBtn "Step 6 - Load scene to test IES"
	)

	fn AssignControllers = 
	(
		try (
			LightRadiusController.value = $VRayLight_Prev.size0
			$VRayLight_Prev.size0.controller=LightRadiusController
			$VRayLight_Final.size0.controller=LightRadiusController
			$Distance_to_light.radius.controller = LightRadiusController
			spnLightRadius.enabled = true
		)catch(
			spnLightRadius.enabled = false
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
	
	on createBtn pressed do (
		local fname = ""
		local ramIES = stringstream "" -- create RAM file
		local startTime =timeGetTime()
		if ManufacTxt.text != "noname" then fName = fName+ManufacTxt.text
		if LumcatTxt.text != "noname" then fName = fName+"-"+LumcatTxt.text
		if fname!="" then fname = fname + ".ies"

			fname = getSaveFileName caption:"Choose path to save the model" filename:(if fname!="" then fname else "") initialDir:maxfilepath types:"IES File|*.ies|All|*.*"
			if fname!= undefined then
			(
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
					"1 1 "+(PowerSpin.value as string)+"\n") to:ramIES
					
				for i = 0.0 to 180.0 by step_w do (last = i; format (i as string + " ") to:ramIES)
				--if last<180 then (format "180.0" to:ramIES)
				format "\n" to:ramIES
	
				for i = 0.0 to 360.0 by step_h do (last = i; format (i as string + " ") to:ramIES)
				--if last<360 then (format "360.0" to:ramIES)
				format "\n" to:ramIES
				--for i = 0 to bw-1 do format (i as string + " ") to:ramIES
				--format "\n" to:ramIES
				for i = 1 to bw do format (ies_lines[i] + "\n") to:ramIES
					
				--try (
					newIES = createfile (IESfromCaustics_TmpPath + filenameFromPath fname)
					print ramIES to:newIES
					close newIES
					-- move to work dir
					if doesFileExist fname then (
						if deleteFile fname then (
							copyFile (IESfromCaustics_TmpPath + filenameFromPath fname) fname
							messagebox ("File write success! :)\nRunning time: "+formatTime(timeGetTime() - startTime))
						) else (messagebox "Can`t overwrite file")
					) else (
						copyFile (IESfromCaustics_TmpPath + filenameFromPath fname) fname
						messagebox ("File write success! :)\nRunning time: " + formatTime (timeGetTime() - startTime))
					)
					deleteFile (IESfromCaustics_TmpPath + filenameFromPath fname)
				--)catch(messagebox "Something is wrong :("; try (close newIES)catch())
				free ramIES
			) else (messagebox "Operation Canceled")
	)
	
	on IESfromCaustics_main_rollout rolledUp state do ( 
		resizeFloater()
	)
	
	on IESfromCaustics_main_rollout close do undo off 
	(
		RollPos = Pankov_IESfromCaustic_Fltr.pos
		/*if chkDeletCausticsOnExit.state then (
			if doesfileexist ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap") then 
				if querybox "Really delete created caustics file?" then (
					deletefile ((getDir #userScripts)+"\\IESfromCaustics\\caustics.vrpmap")
					chkUsePrecalcCaustics.checked = false
				)*/
			if doesfileexist (IESfromCaustics_TmpPath+"last_IEScaustics_calc.vrpmap") then 
				deletefile (IESfromCaustics_TmpPath+"last_IEScaustics_calc.vrpmap")
		--)
		setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos" (RollPos as string)
		if IESfromCaustics_settings_rollout.chkSaveDefaults.checked then (
			saveDefaultsToINI ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		) else (
			setIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustics_main_rollout" "chkSaveDefaults" ("#(#state, "+(IESfromCaustics_settings_rollout.chkSaveDefaults.checked as string)+")")
		)
	)
	
	on IESfromCaustics_main_rollout open do undo off 
	(
		try(t=trackviewnodes;
			n=t[#Anim_Layer_Control_Manager];	deleteTrackViewController t n.controller;
			n=t[#Max_MotionClip_Manager];deleteTrackViewController t n.controller;
			n=t[#Retimer_Manager];deleteTrackViewController t n.controller;
			gc();
		)catch()
		--txtTmpPath.text =wrapString IESfromCaustics_TmpPath
		loadDefaultsFromINI ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini")
		RollPos = getIniSetting ((getDir #userScripts)+"\\IESfromCaustics\\defaults.ini") "IESfromCaustic_Settings" "WindowPos"
		if RollPos != "" and RollPos != undefined do (
			if not keyboard.escPressed do Pankov_IESfromCaustic_Fltr.pos = (execute RollPos)
		)
		
		-- Assign Controllers
		AssignControllers ()
	)
)

rollout IESfromCaustics_webcheck_rollout "About" 
(
--timer tm interval:100 active:true
dotNetControl wb "System.Windows.Forms.WebBrowser" width:315 height:113 pos:[0,0] 

	on IESfromCaustics_webcheck_rollout open do
	(
		Padding 
		wb.ScrollBarsEnabled =false
		wb.url = dotNetObject "System.Uri" (IESfromCaustics_TmpPath + "http/scriptlogo.htm")
		wb.Left = -11
		wb.Top  = -14
		--wb.AllowNavigation = false
		IESfromCaustics_webcheck_rollout.height=80
	)

	on IESfromCaustics_webcheck_rollout rolledUp state do ( 
		resizeFloater()
	)
	
)

addRollout IESfromCaustics_webcheck_rollout Pankov_IESfromCaustic_Fltr rolledUp:false
addRollout IESfromCaustics_main_rollout Pankov_IESfromCaustic_Fltr rolledUp:false
addRollout IESfromCaustics_settings_rollout Pankov_IESfromCaustic_Fltr rolledUp:false
resizeFloater()
