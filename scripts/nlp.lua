-- Required libraries


--解析语音识别结果
function parseASR(xmlstr)

    local retmsg = ""
    local xmlParser = require("xmlSimple").newParser()
        local parsedXml = xmlParser:ParseXmlText(xmlstr)

    if(parsedXml.result == nil) then
        freeswitch.consoleLog("INFO","parseASR>>result is 'nil'\n")
        return nil
    end

    if (parsedXml.result.interpretation.input == nil) then
        freeswitch.consoleLog("parseASR","parseASR>>result.interpretation.input is 'nil'\n")
    else
        retmsg = parsedXml.result.interpretation.input:value()
        freeswitch.consoleLog("parseASR","parseASR>>Result is ".. retmsg  .."\n")
    end

    return retmsg
end

--解析新的语音识别结果格式
function parseASRNew(xmlstr)
    local retmsg = ""
    local xmlParser = require("xmlSimple").newParser()
    local parsedXml = xmlParser:ParseXmlText(xmlstr)

    if(parsedXml.result == nil) then
        freeswitch.consoleLog("INFO","parseASRNew>>result is 'nil'\n")
        return nil
    end

    if (parsedXml.result.interpretation.instance.nlresult == nil) then
        freeswitch.consoleLog("INFO","parseASRNew>>result.interpretation.instance.nlresult is 'nil'\n")
        return nil
    else
        -- 从nlresult中提取文本，格式为 "id|text"
        local fullText = parsedXml.result.interpretation.instance.nlresult:value()
        -- 使用|分割，取第二部分作为实际文本
        local parts = {}
        for part in fullText:gmatch("[^|]+") do
            table.insert(parts, part)
        end
        if #parts >= 2 then
            retmsg = parts[2]
            freeswitch.consoleLog("INFO","parseASRNew>>Result is ".. retmsg .."\n")
        end
    end

    return retmsg
end

--解析火山引擎语音识别结果
function parseVolcengineASR(xmlstr)
    local retmsg = ""
    local xmlParser = require("xmlSimple").newParser()
    local parsedXml = xmlParser:ParseXmlText(xmlstr)

    if(parsedXml.result == nil) then
        freeswitch.consoleLog("INFO","parseVolcengineASR>>result is 'nil'\n")
        return nil
    end

    if (parsedXml.result.interpretation.instance.result == nil) then
        freeswitch.consoleLog("INFO","parseVolcengineASR>>result.interpretation.instance.result is 'nil'\n")
        return nil
    else
        retmsg = parsedXml.result.interpretation.instance.result:value()
        if(retmsg ~= nil) then
            freeswitch.consoleLog("INFO","parseVolcengineASR>>Result is ".. retmsg .."\n")
        else
            freeswitch.consoleLog("INFO","parseVolcengineASR>>Result is 'nil'\n")
        end
    end

    return retmsg
end

function to_agent(skillid)
    if not session:ready() then
        return
    end

    local caller = session:getVariable("caller_id_number");
    writeLog2("this call caller is：" .. caller)

    local customer_level = "1";
    session:execute("set", "customer_level=" .. customer_level)

    session:setVariable("last_channel_operator", "inbound")
    session:execute("log", "INFO enter to_agent:" .. skillid)
    session:execute("transfer", skillid .. " xml public")
end

-- 定义一个函数来进行判断
function check_string_hangup(str)
    -- 检查是否以“退下吧”或“挂机吧”结尾
    local ends_with = string.sub(str, -3) == "退下吧" or string.sub(str, -3) == "挂机吧"
    -- 检查是否包含“退下”、“挂机”或“结束通话”
    local contains = string.find(str, "退下") or string.find(str, "挂机") or string.find(str, "结束通话")

    return ends_with or contains
end

-- 定义一个函数来进行判断是否转人工
function check_string_toagent(str)
    -- 检查是否以“人工”或“转人工”结尾
    local ends_with = string.sub(str, -2) == "人工" or string.sub(str, -3) == "转人工"
    -- 检查是否包含“人工”、“转人工”或“转人工吧”
    local contains = string.find(str, "人工") or string.find(str, "转人工") or string.find(str, "转人工吧")

    return ends_with or contains
end

function writeLog2(msg)
    freeswitch.consoleLog("notice", msg .. "\n")
end

function fire_event_nlp()
    local event = freeswitch.Event("CUSTOM", "IVR_EVENT_NLP")
    event:addHeader("Unique-ID", session:get_uuid())
    freeswitch.consoleLog("NOTICE", "fire_event_nlp: " .. session:get_uuid() .. "\n")
    event:fire()
    writeLog2("fire_event_nlp")
end

function fire_event_nlp_text(text)
    local event = freeswitch.Event("CUSTOM", "IVR_EVENT_NLP")
    event:addHeader("Unique-ID", session:get_uuid())
    event:addHeader("variable_chilli_nlp_text", text)
    freeswitch.consoleLog("NOTICE", "fire_event_nlp_text: " .. session:get_uuid() .. "\n")
    event:fire()
    writeLog2("fire_event_nlp_text")
end

function fire_event_asr_text(text)
    local event = freeswitch.Event("CUSTOM", "IVR_EVENT_NLP")
    event:addHeader("Unique-ID", session:get_uuid())
    event:addHeader("variable_chilli_asr_text", text)
    freeswitch.consoleLog("NOTICE", "fire_event_asr_text: " .. session:get_uuid() .. "\n")
    event:fire()
    writeLog2("fire_event_asr_text")
end

--流程开始
local is_toagent = false
fire_event_nlp()
local taskId = session:getVariable("taskId") or "taskId"
local task_callid = session:getVariable("chilli_callid") or "task_callid"
local task_skill_id = session:getVariable("skill_id") or "task_skill_id"
local task_business_id = session:getVariable("business_id") or "task_business_id"
local voice_name = session:getVariable("voice_name") or "502001"
freeswitch.consoleLog("INFO", "taskinfo taskId is:" .. taskId .. ",task_callid is:".. task_callid ..",task_skill_id is:".. task_skill_id ..",task_business_id is:".. task_business_id ..",voice_name is:".. voice_name .."'\n")

local tryagain = 1
function MySessionHangupHook(s, status, arg)
    freeswitch.consoleLog("INFO", "sessionHangupHook: " .. status .. "\n")
    tryagain = 0
end

blah = "w00t";
session:setHangupHook("MySessionHangupHook", "blah")
session:answer()
session:set_tts_params("unimrcp", voice_name);

welcome = "ivr/empty.wav"
grammar = "hello"
no_input_timeout = 80000
recognition_timeout = 80000
--
local whileNums = 0 
local dispoA = "None"
dispoA = session:getVariable("endpoint_disposition")
while (session:ready() == true and tryagain == 1) do
--
    --启用忙音检测
    while (session:ready() == true and dispoA == "EARLY MEDIA") do
        dispoA = session:getVariable("endpoint_disposition")
        freeswitch.consoleLog("INFO", "启用忙音检测:'" .. dispoA .. "'\n")
        session:sleep(500)
    end

    whileNums = whileNums + 1
    if (whileNums == 1) then
        session:speak("您好，我是您的AI助手，请问有什么可以帮您的？")
    else
	    xml = nil
		freeswitch.consoleLog("INFO","repeat begin...\n")
        
		session:execute("play_and_detect_speech",welcome .. " detect:unimrcp {start-input-timers=false,no-input-timeout=" .. no_input_timeout .. ",recognition-timeout=" .. recognition_timeout .. "}" .. grammar)
		xml = session:getVariable('detect_speech_result')
 --
		if (xml == nil) then
			freeswitch.consoleLog("ERROR","[ASR] Result is 'nil'\n")
			tryagain = 0
		else
			freeswitch.consoleLog("INFO","[ASR] Result is '" .. xml .. "'\n")
			
			if(xml == "Completion-Cause: 002" or xml == "Completion-Cause: 002 no-input-timeout") 
			then
				freeswitch.consoleLog("INFO","[ASR]speech input timeout...\n")
				break
			end		
			
			--解析语音识别结果
			--local asrmsg = parseASRNew(xml)
			local asrmsg = parseVolcengineASR(xml)
			if(asrmsg == nil)
			then
				freeswitch.consoleLog("INFO","[ASR]asrmsg is nil\n")
				break
			end
			freeswitch.consoleLog("INFO","[ASR]parseASR>>Result is '" .. asrmsg .. "'\n")	
			fire_event_asr_text(asrmsg)
			
            -- 调用非流式API
            local aiResponse = callDeepSeekChat(asrmsg)
            if aiResponse then
                freeswitch.consoleLog("INFO","[DeepSeek]Response: " .. aiResponse .. "\n")
                fire_event_nlp_text(aiResponse)
                session:speak(aiResponse)
                --welcome = "say:unimrcp:Chris:" .. aiResponse
                -- 添加短暂延迟，等待TTS完成
                --session:sleep(500)
                -- 继续下一轮对话
                tryagain = 1
            else
                freeswitch.consoleLog("ERROR","[DeepSeek]Failed to get response\n")
                session:speak("抱歉，系统暂时无法处理您的请求。")
                -- 出错时结束对话
                tryagain = 0
            end

            -- 创建流式回调函数处理 DeepSeek 响应
-- 			local function streamCallback(data)
-- 				freeswitch.consoleLog("INFO", "[DeepSeek] Received: " .. data.content .. "\n")
-- 				-- 使用TTS播放当前片段
-- 				session:speak(data.content)
-- 			end
			
-- 			-- 调用流式API
-- 			local streamSuccess = callDeepSeekChatStream(asrmsg, streamCallback)
-- 			if not streamSuccess then
-- 				freeswitch.consoleLog("ERROR", "[DeepSeek] Failed to get streaming response\n")
-- 				session:speak("抱歉，系统暂时无法处理您的请求。")
--                 --出错时结束对话
--                 tryagain = 0
-- 			end

            if check_string_hangup(asrmsg) ~= nil then
			    freeswitch.consoleLog("INFO","用户要求挂机\n")
			    session:hangup()
			    tryagain = 0
			    break
			end
            
            if check_string_toagent(asrmsg) ~= nil then
			    freeswitch.consoleLog("INFO","用户要求转人工\n")
			    to_agent(task_skill_id)
			    tryagain = 0
			    is_toagent = true
			    break
			end

		end
		
		freeswitch.consoleLog("INFO","repeat end...\n")
	end
end

-- session:streamFile(welcome)
--
-- 不是转人工则挂机
if(is_toagent == false) then
  session:sleep(250)
  session:hangup()
end
