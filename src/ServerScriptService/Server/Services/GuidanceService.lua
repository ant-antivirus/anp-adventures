local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local CharacterConfig = require(Shared.Config.CharacterConfig)

local GuidanceService = {}

local playerDataService = nil
local questService = nil
local analyticsService = nil

local CHARACTER_NAMES = {
	[CharacterConfig.Ids.Atom] = "Atom",
	[CharacterConfig.Ids.Neutron] = "Neutron",
	[CharacterConfig.Ids.Proton] = "Proton",
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function characterName(characterId)
	return CHARACTER_NAMES[characterId] or "Guide"
end

local function getObjectiveText(questDefinition, objectiveId)
	local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
	if objectiveDefinition and objectiveDefinition.ObjectiveText then
		return objectiveDefinition.ObjectiveText
	end

	return objectiveId
end

local function buildCharacterHint(characterId, guidanceType, objectiveText)
	if guidanceType == "StartQuest001" then
		if characterId == CharacterConfig.Ids.Proton then
			return "มองหาสัญลักษณ์สีเขียวเพื่อเริ่มภารกิจในศูนย์บัญชาการ"
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "เราต้องเริ่มการสำรวจก่อน จึงจะวิเคราะห์เบาะแสได้"
		end

		return "เริ่มการสำรวจ ANP ครั้งแรกที่จุดเริ่มภารกิจที่ 1"
	elseif guidanceType == "NextObjective" then
		if characterId == CharacterConfig.Ids.Proton then
			return "ขั้นตอนถัดไป: " .. objectiveText
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "มาสำรวจเบาะแสถัดไปกัน: " .. objectiveText
		end

		return "เดินหน้าต่อ เป้าหมายถัดไปคือ: " .. objectiveText
	elseif guidanceType == "CompleteQuest" then
		if characterId == CharacterConfig.Ids.Proton then
			return "ทำเป้าหมายครบแล้ว มองหาสัญลักษณ์สีฟ้าเพื่อส่งภารกิจ"
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "ข้อมูลที่ต้องใช้ครบแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		end

		return "ทำได้ดีมาก กลับไปที่สัญลักษณ์สีฟ้าเพื่อจบภารกิจนี้"
	elseif guidanceType == "CompleteQuest002" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "แผนที่สัญญาณครบแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "แผนที่สัญญาณพร้อมแล้ว ใช้สัญลักษณ์สีฟ้าเพื่อจบภารกิจ"
		end

		return "บันทึกข้อมูลสัญญาณครบแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest002Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 2 พร้อมแล้ว ร่องรอยสัญญาณถัดไปอยู่ในพื้นที่นักสำรวจจักรวาล"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 2 พร้อมแล้ว ไปที่สัญลักษณ์สีเขียวในพื้นที่นักสำรวจจักรวาล"
		end

		return "ภารกิจที่ 2 พร้อมแล้ว มองหาสัญลักษณ์สีเขียวในพื้นที่นักสำรวจจักรวาล"
	elseif guidanceType == "Quest003Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 3 พร้อมแล้ว แผนที่สัญญาณจะพาเราเข้าไปลึกขึ้น"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 3 พร้อมแล้ว ตามสัญลักษณ์สีเขียวถัดไป"
		end

		return "ภารกิจที่ 3 พร้อมแล้ว ตามสัญลักษณ์สีเขียวถัดไป"
	elseif guidanceType == "CompleteQuest003" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ชิ้นส่วนจักรวาลเสถียรแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วนจักรวาลปลอดภัยแล้ว ใช้สัญลักษณ์สีฟ้าเพื่อจบขั้นตอนนี้"
		end

		return "ชิ้นส่วนจักรวาลปลอดภัยแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest004Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 4 พร้อมแล้ว เบาะแสถัดไปชี้ไปยังพื้นที่จำลองพื้นดิน"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 4 พร้อมแล้ว ไปตามทางสู่พื้นที่จำลองพื้นดิน"
		end

		return "ภารกิจที่ 4 พร้อมแล้ว มองหาสัญลักษณ์สีเขียวใกล้พื้นที่จำลองพื้นดิน"
	elseif guidanceType == "CompleteQuest004" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ข้อมูลชิ้นส่วนโลกครบแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วนโลกพร้อมแล้ว จบภารกิจที่สัญลักษณ์สีฟ้า"
		end

		return "ชิ้นส่วนโลกพร้อมแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest005Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 5 พร้อมแล้ว เส้นทางดาวเทียมนำไปสู่ข้อมูล THEOS"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 5 พร้อมแล้ว ตามเส้นทางดาวเทียมไปยังศูนย์ THEOS"
		end

		return "ภารกิจที่ 5 พร้อมแล้ว ตามเส้นทางดาวเทียมไปยังศูนย์ THEOS"
	elseif guidanceType == "CompleteQuest005" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "สัญญาณชิ้นส่วน THEOS เสถียรแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วน THEOS ปลอดภัยแล้ว ใช้สัญลักษณ์สีฟ้าเพื่อจบภารกิจ"
		end

		return "ชิ้นส่วน THEOS ปลอดภัยแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest006Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 6 พร้อมแล้ว สัญญาณดาวเทียมชี้ไปยังภารกิจจรวด"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 6 พร้อมแล้ว ตามเส้นทางจรวดไปยังพื้นที่ภารกิจจรวด"
		end

		return "ภารกิจที่ 6 พร้อมแล้ว ตามเส้นทางจรวดไปยังพื้นที่ภารกิจจรวด"
	elseif guidanceType == "CompleteQuest006" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ข้อมูลชิ้นส่วนจรวดพร้อมแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วนจรวดพร้อมแล้ว จบภารกิจที่สัญลักษณ์สีฟ้า"
		end

		return "ชิ้นส่วนจรวดพร้อมแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest007Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ชิ้นส่วนจรวดปลอดภัยแล้ว ภารกิจที่ 7 พร้อมแล้ว การฝึกนักบินอวกาศจะช่วยเตรียมเรา"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วนจรวดปลอดภัยแล้ว ภารกิจที่ 7 พร้อมแล้ว ไปฝึกนักบินอวกาศกัน"
		end

		return "ชิ้นส่วนจรวดปลอดภัยแล้ว ภารกิจที่ 7 พร้อมแล้ว ไปฝึกนักบินอวกาศกัน"
	elseif guidanceType == "CompleteQuest007" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ฝึกนักบินอวกาศครบแล้ว ไปส่งภารกิจที่สัญลักษณ์สีฟ้า"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ฝึกนักบินอวกาศครบแล้ว ใช้สัญลักษณ์สีฟ้าเพื่อจบภารกิจ"
		end

		return "ฝึกนักบินอวกาศครบแล้ว มองหาสัญลักษณ์สีฟ้า"
	elseif guidanceType == "Quest008Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ภารกิจที่ 8 พร้อมแล้ว ภารกิจเดินบนดวงจันทร์เริ่มได้แล้ว"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ภารกิจที่ 8 พร้อมแล้ว ไปยังพื้นที่เดินบนดวงจันทร์"
		end

		return "ภารกิจที่ 8 พร้อมแล้ว ไปยังพื้นที่เดินบนดวงจันทร์"
	elseif guidanceType == "CompleteQuest008" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "ชิ้นส่วนสตาร์คอร์ครบแล้ว จบตอนที่ 1 ที่สัญลักษณ์สีฟ้าสุดท้าย"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "ชิ้นส่วนสตาร์คอร์ครบแล้ว ไปจบตอนที่ 1 ที่สัญลักษณ์สีฟ้าสุดท้าย"
		end

		return "ชิ้นส่วนสตาร์คอร์ครบแล้ว จบตอนที่ 1 ที่สัญลักษณ์สีฟ้าสุดท้าย"
	elseif guidanceType == "Episode1Complete" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "จบตอนที่ 1 แล้ว ฟื้นฟูสตาร์คอร์ส่วนที่ 1 สำเร็จ"
		elseif characterId == CharacterConfig.Ids.Atom then
			return "จบตอนที่ 1 แล้ว ฟื้นฟูสตาร์คอร์ส่วนที่ 1 สำเร็จ"
		end

		return "จบตอนที่ 1 แล้ว ฟื้นฟูสตาร์คอร์ส่วนที่ 1 สำเร็จ"
	end

	return "สำรวจจุดค้นพบใกล้ ๆ หรือกลับไปที่ศูนย์บัญชาการ"
end

local QUEST_002_OBJECTIVE_HINTS = {
	obj_ep01_main_002_001 = {
		Atom = "ออกเดินทาง ไปยังพื้นที่นักสำรวจจักรวาลและเข้าสู่เขตภารกิจ",
		Neutron = "เราต้องดูสัญญาณในพื้นที่จริง เข้าพื้นที่นักสำรวจจักรวาลก่อน",
		Proton = "เดินทางไปยังพื้นที่นักสำรวจจักรวาลและเข้าสู่เขตภารกิจ",
	},
	obj_ep01_main_002_002 = {
		Atom = "ตามสัญญาณไป หาสัญลักษณ์สัญญาณจุดแรก",
		Neutron = "แหล่งสัญญาณน่าจะอยู่ใกล้ ๆ หาสัญลักษณ์จุดแรกให้เจอ",
		Proton = "หาสัญลักษณ์สัญญาณจุดแรกในพื้นที่นักสำรวจจักรวาล",
	},
	obj_ep01_main_002_003 = {
		Atom = "สแกนสัญลักษณ์และเก็บข้อมูลให้ปลอดภัย",
		Neutron = "สแกนสัญลักษณ์สัญญาณเพื่อดูรูปแบบของมัน",
		Proton = "สแกนสัญลักษณ์เพื่อเก็บข้อมูลสัญญาณ",
	},
	obj_ep01_main_002_004 = {
		Atom = "นำข้อมูลสัญญาณกลับมาเพื่อวิเคราะห์",
		Neutron = "นำข้อมูลสัญญาณกลับมาที่สถานีวิเคราะห์ของฉัน",
		Proton = "นำข้อมูลสัญญาณกลับไปที่สถานีวิเคราะห์ของนิวตรอน",
	},
}

local QUEST_003_OBJECTIVE_HINTS = {
	obj_ep01_main_003_001 = {
		Atom = "ตามร่องรอยสัญญาณดาวเข้าไปลึกขึ้น",
		Neutron = "สัญญาณที่ทำแผนที่ไว้กำลังยืดออก ตามร่องรอยสัญญาณดาวไป",
		Proton = "ตามร่องรอยสัญญาณดาวเข้าไปในพื้นที่นักสำรวจจักรวาล",
	},
	obj_ep01_main_003_002 = {
		Atom = "ตรวจเสียงสะท้อนสัญญาณที่ไม่เสถียรและค่อย ๆ ทำ",
		Neutron = "ตรวจเสียงสะท้อนสัญญาณ เพื่อเข้าใจความผิดเพี้ยน",
		Proton = "ตรวจเสียงสะท้อนสัญญาณที่ไม่เสถียร",
	},
	obj_ep01_main_003_003 = {
		Atom = "ทำให้ชิ้นส่วนจักรวาลเสถียรก่อนที่มันจะจางหาย",
		Neutron = "ทำให้ชิ้นส่วนจักรวาลเสถียรก่อนสัญญาณจะหายไป",
		Proton = "ทำให้ชิ้นส่วนจักรวาลเสถียร",
	},
	obj_ep01_main_003_004 = {
		Atom = "เก็บชิ้นส่วนจักรวาล",
		Neutron = "เก็บชิ้นส่วนจักรวาลไว้ในบันทึกของสตาร์คอร์",
		Proton = "เก็บชิ้นส่วนจักรวาล",
	},
}

local QUEST_004_OBJECTIVE_HINTS = {
	obj_ep01_main_004_001 = {
		Atom = "เดินทางไปยังพื้นที่จำลองพื้นดิน",
		Neutron = "ไปยังพื้นที่จำลองพื้นดิน เพื่อเทียบข้อมูลความทรงจำพื้นดิน",
		Proton = "เดินทางไปยังพื้นที่จำลองพื้นดิน",
	},
	obj_ep01_main_004_002 = {
		Atom = "หาสัญลักษณ์ความทรงจำของโลก",
		Neutron = "หาสัญลักษณ์ความทรงจำของโลก มันน่าจะบอกแบบพื้นดินได้",
		Proton = "หาสัญลักษณ์ความทรงจำของโลก",
	},
	obj_ep01_main_004_003 = {
		Atom = "ประกอบเส้นทางความทรงจำพื้นดิน",
		Neutron = "ประกอบเส้นทางความทรงจำ เพื่อให้ชิ้นส่วนโลกเสถียร",
		Proton = "ประกอบเส้นทางความทรงจำพื้นดิน",
	},
	obj_ep01_main_004_004 = {
		Atom = "เก็บชิ้นส่วนโลก",
		Neutron = "เก็บชิ้นส่วนโลกเมื่อความทรงจำพื้นดินเสถียรแล้ว",
		Proton = "เก็บชิ้นส่วนโลก",
	},
}

local QUEST_005_OBJECTIVE_HINTS = {
	obj_ep01_main_005_001 = {
		Atom = "เดินทางไปยังศูนย์ดาวเทียม THEOS",
		Neutron = "ไปยังศูนย์ดาวเทียม THEOS เพื่อดูข้อมูลดาวเทียม",
		Proton = "เดินทางไปยังศูนย์ดาวเทียม THEOS",
	},
	obj_ep01_main_005_002 = {
		Atom = "ตรวจคลังข้อมูลดาวเทียมเพื่อหาสัญญาณที่หายไป",
		Neutron = "ตรวจคลังข้อมูลดาวเทียมเพื่อดูรูปแบบสัญญาณที่หายไป",
		Proton = "ตรวจคลังข้อมูลดาวเทียมเพื่อหาสัญญาณที่หายไป",
	},
	obj_ep01_main_005_003 = {
		Atom = "ซ่อมตัวส่งต่อสัญญาณ",
		Neutron = "ซ่อมตัวส่งต่อสัญญาณเพื่อให้ชิ้นส่วน THEOS เสถียร",
		Proton = "ซ่อมตัวส่งต่อสัญญาณ",
	},
	obj_ep01_main_005_004 = {
		Atom = "เก็บชิ้นส่วน THEOS",
		Neutron = "เก็บชิ้นส่วน THEOS เมื่อตัวส่งต่อสัญญาณเสถียรแล้ว",
		Proton = "เก็บชิ้นส่วน THEOS",
	},
}

local QUEST_006_OBJECTIVE_HINTS = {
	obj_ep01_main_006_001 = {
		Atom = "เดินทางไปยังพื้นที่ภารกิจจรวด",
		Neutron = "ไปยังพื้นที่ภารกิจจรวดเพื่อตรวจเส้นทางปล่อยจรวด",
		Proton = "เดินทางไปยังพื้นที่ภารกิจจรวด",
	},
	obj_ep01_main_006_002 = {
		Atom = "ตรวจแผงควบคุมจรวด",
		Neutron = "ตรวจแผงควบคุมจรวดเพื่อดูข้อมูลระบบปล่อย",
		Proton = "ตรวจแผงควบคุมจรวด",
	},
	obj_ep01_main_006_003 = {
		Atom = "ตรวจระบบก่อนปล่อยจรวด",
		Neutron = "ตรวจระบบก่อนปล่อยเพื่อยืนยันเส้นทางจรวด",
		Proton = "ตรวจระบบก่อนปล่อยจรวด",
	},
	obj_ep01_main_006_004 = {
		Atom = "เก็บชิ้นส่วนจรวด",
		Neutron = "เก็บชิ้นส่วนจรวดหลังตรวจระบบเสร็จ",
		Proton = "เก็บชิ้นส่วนจรวด",
	},
}

local QUEST_007_OBJECTIVE_HINTS = {
	obj_ep01_main_007_001 = {
		Atom = "เดินทางไปยังพื้นที่ฝึกนักบินอวกาศ",
		Neutron = "ไปยังพื้นที่ฝึกนักบินอวกาศเพื่อยืนยันความพร้อม",
		Proton = "เดินทางไปยังพื้นที่ฝึกนักบินอวกาศ",
	},
	obj_ep01_main_007_002 = {
		Atom = "ผ่านสถานีฝึกการเคลื่อนที่",
		Neutron = "ผ่านสถานีฝึกการเคลื่อนที่ เพื่อทดสอบการควบคุมแบบอวกาศ",
		Proton = "ผ่านสถานีฝึกการเคลื่อนที่",
	},
	obj_ep01_main_007_003 = {
		Atom = "ตรวจความปลอดภัยของออกซิเจน",
		Neutron = "ตรวจความปลอดภัยของออกซิเจนก่อนรับอนุญาตไปดวงจันทร์",
		Proton = "ตรวจความปลอดภัยของออกซิเจน",
	},
	obj_ep01_main_007_004 = {
		Atom = "รับอนุญาตสำหรับภารกิจดวงจันทร์",
		Neutron = "รับอนุญาตภารกิจดวงจันทร์หลังตรวจความปลอดภัยครบ",
		Proton = "รับอนุญาตสำหรับภารกิจดวงจันทร์",
	},
}

local QUEST_008_OBJECTIVE_HINTS = {
	obj_ep01_main_008_001 = {
		Atom = "เดินทางไปยังพื้นที่เดินบนดวงจันทร์",
		Neutron = "ไปยังพื้นที่เดินบนดวงจันทร์เพื่อตามสัญญาณสุดท้าย",
		Proton = "เดินทางไปยังพื้นที่เดินบนดวงจันทร์",
	},
	obj_ep01_main_008_002 = {
		Atom = "ตามร่องรอยสัญญาณดวงจันทร์",
		Neutron = "ตามร่องรอยสัญญาณดวงจันทร์และดูการเปลี่ยนแปลงของชิ้นส่วน",
		Proton = "ตามร่องรอยสัญญาณดวงจันทร์",
	},
	obj_ep01_main_008_003 = {
		Atom = "เก็บชิ้นส่วนดวงจันทร์",
		Neutron = "เก็บชิ้นส่วนดวงจันทร์ก่อนการฟื้นฟูสุดท้าย",
		Proton = "เก็บชิ้นส่วนดวงจันทร์",
	},
	obj_ep01_main_008_004 = {
		Atom = "ตรวจชุดชิ้นส่วนของตอนที่ 1",
		Neutron = "ตรวจชิ้นส่วนทั้งห้าของตอนที่ 1 ก่อนฟื้นฟูส่วนหลัก",
		Proton = "ตรวจชิ้นส่วนทั้งหมดของตอนที่ 1",
	},
	obj_ep01_main_008_005 = {
		Atom = "ฟื้นฟูสตาร์คอร์ส่วนที่ 1",
		Neutron = "ฟื้นฟูสตาร์คอร์ส่วนที่ 1 ด้วยชุดชิ้นส่วนที่ครบแล้ว",
		Proton = "ฟื้นฟูสตาร์คอร์ส่วนที่ 1",
	},
}

local function getCharacterToneKey(characterId)
	if characterId == CharacterConfig.Ids.Atom then
		return "Atom"
	elseif characterId == CharacterConfig.Ids.Neutron then
		return "Neutron"
	elseif characterId == CharacterConfig.Ids.Proton then
		return "Proton"
	end

	return "Proton"
end

local function buildQuestObjectiveHint(characterId, questId, objectiveId, objectiveText)
	if questId == "quest_ep01_main_002" then
		local objectiveHints = QUEST_002_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_003" then
		local objectiveHints = QUEST_003_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_004" then
		local objectiveHints = QUEST_004_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_005" then
		local objectiveHints = QUEST_005_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_006" then
		local objectiveHints = QUEST_006_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_007" then
		local objectiveHints = QUEST_007_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_008" then
		local objectiveHints = QUEST_008_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	end

	return buildCharacterHint(characterId, "NextObjective", objectiveText)
end

local function getActiveQuestId(questSnapshot)
	local activeQuestIds = {}
	for questId in pairs(questSnapshot.ActiveQuestIds or {}) do
		table.insert(activeQuestIds, questId)
	end
	table.sort(activeQuestIds)

	return activeQuestIds[1]
end

local function getNextIncompleteRequiredObjective(questDefinition, questState)
	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
		local objectiveState = questState.ObjectiveStates and questState.ObjectiveStates[objectiveId]
		if not objectiveState or objectiveState.Completed ~= true then
			return objectiveId
		end
	end

	return nil
end

function GuidanceService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	questService = dependencies.QuestService
	analyticsService = dependencies.AnalyticsService

	assert(playerDataService, "GuidanceService requires PlayerDataService.")
	assert(questService, "GuidanceService requires QuestService.")
end

local function recordGuidanceUse(player, characterId, activeQuestId, nextObjectiveId, hintText)
	playerDataService.Mutate(player, "IncrementSessionStat", {
		SourceType = "SessionStats",
		SourceId = "NPCInteractions",
	}, function(playerData)
		playerData.SessionStats = playerData.SessionStats or {}
		playerData.SessionStats.NPCInteractions = (playerData.SessionStats.NPCInteractions or 0) + 1
		return true
	end)

	if analyticsService then
		analyticsService.Track(player, "NPCGuidanceUsed", {
			CharacterId = characterId,
			ActiveQuestId = activeQuestId,
			NextObjectiveId = nextObjectiveId,
			HintText = hintText,
		})
	end
end

local function guidanceReady(player, data)
	recordGuidanceUse(player, data.CharacterId, data.ActiveQuestId, data.NextObjectiveId, data.HintText)
	return result(true, "GuidanceReady", nil, data)
end

function GuidanceService.GetPlayerGuidance(player, characterId)
	local questSnapshot = playerDataService.GetSnapshot(player, "Quests")
	if not questSnapshot.Success then
		return questSnapshot
	end

	local guideCharacterId = characterId
	local activeQuestId = getActiveQuestId(questSnapshot.Data)

	if activeQuestId then
		local questDefinition = QuestDefinitions[activeQuestId]
		local questStateResult = questService.GetQuestState(player, activeQuestId)
		if not questStateResult.Success then
			return questStateResult
		end

		local nextObjectiveId = getNextIncompleteRequiredObjective(questDefinition, questStateResult.Data)
		if nextObjectiveId then
			local objectiveText = getObjectiveText(questDefinition, nextObjectiveId)
			return guidanceReady(player, {
				CharacterId = guideCharacterId,
				ActiveQuestId = activeQuestId,
				ActiveQuestTitle = questDefinition.Title or activeQuestId,
				NextObjectiveId = nextObjectiveId,
				NextObjectiveText = objectiveText,
				HintText = buildQuestObjectiveHint(guideCharacterId, activeQuestId, nextObjectiveId, objectiveText),
			})
		end

		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = activeQuestId,
			ActiveQuestTitle = questDefinition.Title or activeQuestId,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(
				guideCharacterId,
				if activeQuestId == "quest_ep01_main_002" then "CompleteQuest002"
				elseif activeQuestId == "quest_ep01_main_003" then "CompleteQuest003"
				elseif activeQuestId == "quest_ep01_main_004" then "CompleteQuest004"
				elseif activeQuestId == "quest_ep01_main_005" then "CompleteQuest005"
				elseif activeQuestId == "quest_ep01_main_006" then "CompleteQuest006"
				elseif activeQuestId == "quest_ep01_main_007" then "CompleteQuest007"
				elseif activeQuestId == "quest_ep01_main_008" then "CompleteQuest008"
				else "CompleteQuest"
			),
		})
	end

	local canStartQuest001 = questService.CanStartQuest(player, "quest_ep01_main_001")
	if canStartQuest001 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "StartQuest001"),
		})
	end

	local canStartQuest002 = questService.CanStartQuest(player, "quest_ep01_main_002")
	if canStartQuest002 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest002Available"),
		})
	end

	local canStartQuest003 = questService.CanStartQuest(player, "quest_ep01_main_003")
	if canStartQuest003 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest003Available"),
		})
	end

	local canStartQuest004 = questService.CanStartQuest(player, "quest_ep01_main_004")
	if canStartQuest004 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest004Available"),
		})
	end

	local canStartQuest005 = questService.CanStartQuest(player, "quest_ep01_main_005")
	if canStartQuest005 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest005Available"),
		})
	end

	local canStartQuest006 = questService.CanStartQuest(player, "quest_ep01_main_006")
	if canStartQuest006 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest006Available"),
		})
	end

	local canStartQuest007 = questService.CanStartQuest(player, "quest_ep01_main_007")
	if canStartQuest007 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest007Available"),
		})
	end

	local canStartQuest008 = questService.CanStartQuest(player, "quest_ep01_main_008")
	if canStartQuest008 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest008Available"),
		})
	end

	if questSnapshot.Data.CompletedQuestIds and questSnapshot.Data.CompletedQuestIds.quest_ep01_main_008 == true then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Episode1Complete"),
		})
	end

	return guidanceReady(player, {
		CharacterId = guideCharacterId,
		ActiveQuestId = nil,
		ActiveQuestTitle = nil,
		NextObjectiveId = nil,
		NextObjectiveText = nil,
		HintText = buildCharacterHint(guideCharacterId, "Explore"),
	})
end

function GuidanceService.GetCharacterName(characterId)
	return characterName(characterId)
end

return GuidanceService
