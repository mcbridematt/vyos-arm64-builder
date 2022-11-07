require "pl"

function extractValue(packagestring, key)
	local matchsequence = "'"..key.."':%s?'+([%w%-%/:%.%%]+)'+,"
	local valueit = string.gmatch(packagestring,matchsequence)
	local thismatch = nil
	for match in valueit do
		thismatch = match
		break
	end
	return thismatch
end

function extractBuildCmd(packagestring)
	local startit = string.gmatch(packagestring, "'buildCmd':[%s%c]?'+(.+)")
	for match in startit do
		local endpos = match:find("'+]")
		local substr = match:sub(0, endpos-1)
		-- fix any escape sequences
		substr = substr:gsub("\\","")
		return substr
	end
end
jenkinsfile = file.read("Jenkinsfile")
pkgListStart = jenkinsfile:find("def pkgList = %[")
endPkgList = stringx.rfind(jenkinsfile, "]")
pkgList = jenkinsfile:sub(pkgListStart,endPkgList)
print(pkgList)

curidx = 0
hasnextpackage = pkgList:find("%[",curidx)
packages = {}

while hasnextpackage do
	thispkgend = pkgList:find("],", hasnextpackage+1)
	thispkg = pkgList:sub(hasnextpackage,thispkgend)
	print(thispkg)
	hasnextpackage = pkgList:find("%[",thispkgend)
	packagename = extractValue(thispkg,"name")
	local scmurl = extractValue(thispkg,"scmUrl")
	local scmcommit = extractValue(thispkg,"scmCommit")
	local package_clone_success = false
	if (scmurl ~= nil) and (scmcommit ~= nil) then
		print("Need to clone " .. scmurl .. " commit " .. scmcommit)
		if (scmcommit:find("^%x+") ~= nil) then
			package_clone_success = utils.execute("git clone " .. scmurl .. " " .. packagename .. " && cd " .. packagename .. " && git reset --hard " .. scmcommit)
		else
			local git_clone_command = "git clone --depth=1 --branch='" .. scmcommit .. "' " .. scmurl .. " "  .. packagename
			print(git_clone_command)
			package_clone_success = utils.execute(git_clone_command)
		end
	else
		print("scmurl or commit nil, check this: " .. tostring(scmurl) .. " commit=" .. tostring(scmcommit))
		dir.makepath(packagename)
		package_clone_success = true
	end
	if (package_clone_success) then
		local buildcmd = extractBuildCmd(thispkg)
		utils.writefile(packagename .. "/jenkins_build_cmd.sh",buildcmd)
		packages[#packages+1] = packagename
	else
		print("WARNING: package " .. packagename .. " did not clone successfully")
	end
end
for i,packagename in ipairs(packages) do
	print("Doing compile for " .. packagename)
	local package_build_success = utils.executeex("cd "  .. packagename .. " && sh jenkins_build_cmd.sh")
	if (package_build_success ~= true) then
		print("Error: " .. packagename .. " did not build successfully")
	end
	print("Compile task for " .. packagename .. " done")
end
