-- Reset wallets and re-generate with new rates
UPDATE wallets SET yellow_coins=0, green_coins=0, red_coins=0;
DELETE FROM coin_generation_log;
DELETE FROM transactions;

CALL generate_coins_for_cycle(1);
CALL generate_coins_for_cycle(2);

SELECT user_id, yellow_coins, green_coins, red_coins FROM wallets ORDER BY user_id;
