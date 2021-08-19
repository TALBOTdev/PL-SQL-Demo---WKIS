/* *******************************************
**  Program Name:	CPRG 307 - Assignment 1
**  Author:  	Ben Talbot
**  Created:	April 3, 2020
**  Description:	Processes transactions in the
**  new_transactions table by adding entries into
**  the transaction_history and transaction_detail
**  tables. Also updates the account balances in 
**  the account table and removes successfully 
**  processed transactions from new_transactions.
**  Performs error handling on bad data
******************************************* */

SET serveroutput ON

DECLARE

    k_debit  CONSTANT CHAR := 'D';
    k_credit CONSTANT CHAR := 'C';

    v_current_transaction new_transactions.transaction_no%TYPE := 0;
	v_previous_transaction new_transactions.transaction_no%TYPE := 0;
	v_flagged_transaction new_transactions.transaction_no%TYPE := 0;
	v_account_no new_transactions.account_no%TYPE;
	v_account_balance account.account_balance%TYPE;
	v_account_type account.account_type_code%TYPE;
	v_compare_code account_type.default_trans_type%TYPE;
	v_running_total NUMBER;
	v_error_msg VARCHAR2(200);
	
	ex_missing_trans_no EXCEPTION;
	ex_account_imbalanced EXCEPTION;
	ex_invalid_account_no EXCEPTION;
	ex_negative_trans EXCEPTION;
	ex_invalid_trans_type EXCEPTION;
	
	PRAGMA EXCEPTION_INIT(ex_invalid_trans_type, -2290);
	PRAGMA EXCEPTION_INIT(ex_invalid_account_no, -2291);
	

    CURSOR c_transaction IS
    SELECT *
    FROM new_transactions;
	
	CURSOR c_single_transaction IS
	SELECT * 
	FROM new_transactions
	WHERE transaction_no = v_current_transaction;

BEGIN

    FOR r_transaction IN c_transaction
    LOOP
	BEGIN

        EXIT WHEN c_transaction%NOTFOUND;
		
		
		v_current_transaction := r_transaction.transaction_no;
		v_account_no := r_transaction.account_no;
		
		IF (v_current_transaction IS NULL) THEN
				RAISE ex_missing_trans_no;
		END IF;

		IF (v_current_transaction != v_flagged_transaction OR v_flagged_transaction IS NULL) THEN 			
			IF (r_transaction.transaction_amount < 0) THEN
				RAISE ex_negative_trans;
			END IF;
			
			IF (r_transaction.transaction_type != k_credit AND r_transaction.transaction_type != k_debit) THEN
				RAISE ex_invalid_trans_type;
			END IF;
			
			v_running_total := 0;
			
			-- Tallies up the debits and credits of all rows in a given transaction. 
			FOR r_single_transaction IN c_single_transaction
			LOOP
			BEGIN
			
				EXIT WHEN c_single_transaction%NOTFOUND;
				
				IF (r_single_transaction.transaction_type = k_credit) THEN
					v_running_total := v_running_total + r_single_transaction.transaction_amount;
				ELSE
					v_running_total := v_running_total - r_single_transaction.transaction_amount;
				END IF;
			END;
			END LOOP;
			
			-- Checks if transaction number is new. This way transaction_history will only have 1 entry per transaction.	
			IF (v_previous_transaction != v_current_transaction) THEN
				IF (v_running_total != 0) THEN
					RAISE ex_account_imbalanced;
				ELSE
					INSERT INTO transaction_history
					(transaction_no, transaction_date, description)
					VALUES
					(r_transaction.transaction_no, r_transaction.transaction_date, r_transaction.description);
				END IF;
			END IF;

			-- Adds details from every line into transaction_detail
			INSERT INTO transaction_detail
			(account_no, transaction_no, transaction_type, transaction_amount)
			VALUES
			(r_transaction.account_no, r_transaction.transaction_no, r_transaction.transaction_type, r_transaction.transaction_amount);
			
			SELECT account_balance 
			INTO v_account_balance
			FROM account 
			WHERE account_no = v_account_no;
			
			SELECT account_type_code
			INTO v_account_type
			FROM account
			WHERE account_no = v_account_no;
			
			SELECT default_trans_type
			INTO v_compare_code
			FROM account_type
			WHERE account_type_code = v_account_type;
		
			-- Compares the transaction type with the default transaction type of the current transaction
			-- If equal, the transaction amount is added to the account. If not equal, the transaction amount is subtracted.
			IF (r_transaction.transaction_type = v_compare_code) THEN
				v_account_balance := v_account_balance + r_transaction.transaction_amount;
			ELSE
				v_account_balance := v_account_balance - r_transaction.transaction_amount;
			END IF;
			
			UPDATE account
			SET account_balance = v_account_balance
			WHERE account_no = v_account_no;
		
			-- After the current transaction is finished processing, it is changed to the previous transaction and the line is deleted from new_transactions.
			v_previous_transaction := v_current_transaction;
			
			DELETE FROM new_transactions 
			WHERE transaction_no = r_transaction.transaction_no AND account_no = r_transaction.account_no;
			COMMIT;
		ELSE
			DBMS_OUTPUT.PUT_LINE('Row skipped.');
		END IF;
		
		EXCEPTION	
			WHEN ex_missing_trans_no THEN
				ROLLBACK;
				v_flagged_transaction := v_current_transaction;
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(NULL, r_transaction.transaction_date, r_transaction.description, 'TRANSACTION MISSING TRANSACTION NUMBER.');
				COMMIT;
			WHEN ex_account_imbalanced THEN
				ROLLBACK;
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(v_current_transaction, r_transaction.transaction_date, r_transaction.description, 'TRANSACTION NOT BALANCED, DEBITS AND CREDITS DO NOT EVALUATE TO 0.');

			WHEN ex_invalid_account_no THEN
				ROLLBACK;
				v_flagged_transaction := v_current_transaction;
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(v_current_transaction, r_transaction.transaction_date, r_transaction.description, 'ACCOUNT NUMBER NOT RECOGNIZED.');
				COMMIT;
			WHEN ex_negative_trans THEN
				ROLLBACK;
				v_flagged_transaction := v_current_transaction;
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(v_current_transaction, r_transaction.transaction_date, r_transaction.description, 'NEGATIVE NUMBER PROVIDED FOR TRANSACTION AMOUNT. AMOUNT MUST BE POSITIVE.');
				COMMIT;
			WHEN ex_invalid_trans_type THEN
				ROLLBACK;
				v_flagged_transaction := v_current_transaction;
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(v_current_transaction, r_transaction.transaction_date, r_transaction.description, 'INVALID TRANSACTION TYPE PROVIDED. MUST BE A "C" OR A "D".');
				COMMIT;
			WHEN OTHERS THEN
				ROLLBACK;
				v_flagged_transaction := v_current_transaction;
				v_error_msg := SUBSTR(SQLERRM,1,200); 
				INSERT INTO wkis_error_log
				(transaction_no, transaction_date, description, error_msg)
				VALUES
				(v_current_transaction, r_transaction.transaction_date, r_transaction.description, v_error_msg);
				COMMIT;
	
	END;
	END LOOP;	
	
END;
/