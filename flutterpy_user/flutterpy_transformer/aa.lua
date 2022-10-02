return {
	b = {
		comm_func = function (env, name, composition)
			return require('flutterpy.transformer').get_commit_text(composition) .. '都是北七。'
		end,
		cand_func = function (env, name, composition, candidates)
			if #candidates > 1 then
				candidates[1].text = candidates[1].text .. '是北七吗？'
			end
			return candidates
		end,
		desc = '北七变换器'
	}
}