
--Trigger para baixar o estoque de um PRODUTO quando ele for vendido:
CREATE OR REPLACE FUNCTION atualizar_estoque()
RETURNS TRIGGER AS $$
BEGIN
   UPDATE produto SET quantidade = quantidade - NEW.quantidade
   WHERE codproduto = NEW.codproduto;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER baixar_estoque
AFTER INSERT ON itempedido
FOR EACH ROW
EXECUTE FUNCTION atualizar_estoque(); 

--Trigger para criar um log dos CLIENTES modificados:
CREATE OR REPLACE FUNCTION log_clientes() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ex2_log (data, descricao)
    VALUES (now(), 'Cliente modificado: ' || TG_TABLE_NAME || ' - codcliente: ' || NEW.codcliente);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_modificados
AFTER INSERT OR UPDATE ON cliente
FOR EACH ROW
EXECUTE FUNCTION log_clientes();


--Trigger para criar um LOG quando o valor total do pedido for maior que R$1000:
CREATE OR REPLACE FUNCTION log_valor_total()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.valortotal > 1000 THEN
        INSERT INTO ex2_log (data, descricao)
        VALUES (now(), 'Pedido com valor total maior que R$1000 - codpedido: ' || NEW.codpedido);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valor_total_alto
AFTER INSERT OR UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION log_valor_total();


--Trigger que NÃO permitiu que uma PESSOA com data de nascimento anterior a data de hoje seja inserida ou atualizada:
CREATE OR REPLACE FUNCTION verificar_data_nascimento() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.datanascimento > now()::date THEN
        RAISE EXCEPTION 'Data de nascimento inválida';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verificar_data_nascimento_insert
BEFORE INSERT ON cliente
FOR EACH ROW
EXECUTE FUNCTION verificar_data_nascimento();

CREATE TRIGGER verificar_data_nascimento_update
BEFORE UPDATE ON cliente
FOR EACH ROW
EXECUTE FUNCTION verificar_data_nascimento();


--Trigger que ajusta os pedidos de compra para que não existam itens repetidos:
CREATE OR REPLACE FUNCTION verificar_item_pedido() 
RETURNS TRIGGER AS $$
DECLARE
    qtd_itens INTEGER;
BEGIN
    SELECT COUNT(*) INTO qtd_itens
    FROM itempedido
    WHERE codpedido = NEW.codpedido AND numeroitem = NEW.numeroitem;

    IF qtd_itens > 1 THEN
        RAISE EXCEPTION 'Item de pedido já existe';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verificar_item_pedido_insert
BEFORE INSERT ON itempedido
FOR EACH ROW
EXECUTE FUNCTION verificar_item_pedido();
