function nn.get_bleu(cand, ref, n)
   n = n or 4
   local smooth = 1
   if type(cand) ~= 'table' then
      cand = cand:totable()
   end
   if type(ref) ~= 'table' then
      ref = ref:totable()
   end
   local res = nn.utils.get_ngram_prec(cand, ref, n)
   local brevPen = math.exp(1-math.max(1, #ref/#cand))
   local correct = 0
   local total = 0
   local bleu = 1
   for i = 1, n do
      if res[i][1] > 0 then
         if res[i][2] == 0 then
            smooth = smooth*0.5
            res[i][2] = smooth
         end
         local prec = res[i][2]/res[i][1]
         bleu = bleu * prec
      end
   end
   bleu = bleu^(1/n)
   return bleu*brevPen
end

function nn.get_rougeN(cand, ref, n, weight)
   n = n or 4
   weight = weight or {}
   if #weight == 0 then
      for i=1, n do
	 weight[i] = 0
      end
      weight[n] = 1
   end
   if type(cand) ~= 'table' then
      cand = cand:totable()
   end
   if type(ref) ~= 'table' then
      ref = ref:totable()
   end
   local res = nn.utils.get_ngram_recall(cand, ref, n)
   local correct = 0
   local total = 0
   local rouge = 0
   weight_sum = 0
   
   for i = 1, n do
      local recall = res[i][2]/res[i][1]
      rouge = rouge + recall*weight[i]
      weight_sum = weight_sum + weight[i]
   end
   rouge = rouge/weight_sum
   return rouge
end

function nn.get_rougeS(cand, ref, beta, dskip)
   local beta = beta or 1
   beta = beta * beta

   local dskip = dskip or (#cand - 1)
   if type(cand) ~= 'table' then
      cand = cand:totable()
   end
   if type(ref) ~= 'table' then
      ref = ref:totable()
   end
   local cand_unigrams = nn.utils.get_ngrams(cand, 1)
   local ref_unigrams = nn.utils.get_ngrams(ref, 1)
  
   local cand_skip_bigrams = nn.utils.get_skip_bigrams(cand, ref_unigrams, 1, dskip)
   local ref_skip_bigrams = nn.utils.get_skip_bigrams(ref, cand_unigrams, 1, dskip)
   local correct = 0

   for bigram, dist in pairs(ref_skip_bigrams) do
      local freq = dist[1]
      local length = dist[2]
      local actual
      if cand_skip_bigrams[bigram] == nil then
         actual = 0
      else
         actual = cand_skip_bigrams[bigram][1]
      end
     correct = correct + math.min(actual, freq)
   end
   local rskip2 = 2*correct/(#cand*(#cand - 1))
   local pskip2 = 2*correct/(#ref*(#ref - 1))
   local rouge = (1 + beta)*rskip2*pskip2/(rskip2 + beta*pskip2)
   return rouge
end

