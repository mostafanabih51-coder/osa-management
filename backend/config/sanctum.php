<?php
return ['stateful'=>explode(',',env('SANCTUM_STATEFUL_DOMAINS','')),'guard'=>['web'],'expiration'=>null,'token_prefix'=>env('SANCTUM_TOKEN_PREFIX','')];
