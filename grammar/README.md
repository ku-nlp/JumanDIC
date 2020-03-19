# Updating Juman++ ID mapping

If you are updating files in this directory, you would need to regenerate Juman++ ID mapping.

Script for regeneration: https://github.com/ku-nlp/jumanpp/blob/master/script/grammar_id_mapping.py


How to run:

```
python3 grammar_id_mapping.py \
	--grammar /path/to/grammar/JUMAN.grammar \
	--katuyou /path/to/grammar/JUMAN.katuyou \
	--output /path/to/jumanpp/src/jumandic/shared/jumandic_ids.cc
```