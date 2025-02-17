-- Databricks notebook source
-- MAGIC %md
-- MAGIC O objetivo principal é desenvolver as features relacionadas a método de pagamento \
-- MAGIC 1- GMV por tipo de pagamento - uma feature cada \
-- MAGIC 2- % Pedidos por meio de Pagamento \
-- MAGIC 3- Média quantidade de parcelas (excluindo à vista)

-- COMMAND ----------

-- DBTITLE 1,data check - pagamento
  SELECT
      SUM(CASE WHEN pg.vlPagamento IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_vlPagamento_null,
      SUM(CASE WHEN pg.descTipoPagamento IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_descTipoPagamento_null,
      SUM(CASE WHEN pd.dtPedido IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_dtPedido_null,
      SUM(CASE WHEN pg.nrParcelas  IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_nrParcelas_null
  FROM silver.olist.pagamento_pedido AS pg
      LEFT JOIN silver.olist.pedido AS pd
        ON pd.idPedido = pg.idPedido
 

-- COMMAND ----------

-- DBTITLE 1,1- GMV POR TIPO DE PAGAMENTO
WITH info AS (
  SELECT
      SUM(pg.vlPagamento) AS total_pagto,
      pg.descTipoPagamento AS tp_pagamento,
      date_trunc('month', pd.dtPedido) AS mes_pedido
  FROM silver.olist.pagamento_pedido AS pg
      LEFT JOIN silver.olist.pedido AS pd
        ON pd.idPedido = pg.idPedido
  GROUP BY pg.descTipoPagamento, mes_pedido
)
SELECT
    mes_pedido,
    SUM(CASE WHEN tp_pagamento = 'credit_card' THEN total_pagto ELSE 0 END) AS cartao_credito,
    SUM(CASE WHEN tp_pagamento = 'debit_card' THEN total_pagto ELSE 0 END) AS cartao_debito,
    SUM(CASE WHEN tp_pagamento = 'vouncher' THEN total_pagto ELSE 0 END) AS vouncher,
    SUM(CASE WHEN tp_pagamento = 'not_defined' THEN total_pagto ELSE 0 END) AS not_defined
FROM info
GROUP BY mes_pedido
ORDER BY mes_pedido;


-- COMMAND ----------

-- MAGIC %md
-- MAGIC Dúvidas 
-- MAGIC 1- O que significa cada tipo de pagamento? 
-- MAGIC - vouncher
-- MAGIC - not defined
-- MAGIC - cartao de debito
-- MAGIC - cartao de crédito 
-- MAGIC
-- MAGIC 2- 

-- COMMAND ----------

-- DBTITLE 1,2- % PEDIDOS POR MEIO DE PAGAMENTO
WITH info AS (
  SELECT
      COUNT(DISTINCT pg.idPedido) AS pedidos_unicos,
      pg.descTipoPagamento AS tp_pagamento,
      date_trunc('month', pd.dtPedido) AS mes_pedido
  FROM silver.olist.pagamento_pedido AS pg
      LEFT JOIN silver.olist.pedido AS pd
        ON pd.idPedido = pg.idPedido
  GROUP BY pg.descTipoPagamento, mes_pedido
),
total_pedidos AS (
  SELECT
      mes_pedido,
      SUM(pedidos_unicos) AS total_pedidos
  FROM info
  GROUP BY mes_pedido
)
SELECT
    i.mes_pedido,
    ROUND(100.0 * SUM(CASE WHEN i.tp_pagamento = 'credit_card' THEN i.pedidos_unicos ELSE 0 END) / t.total_pedidos, 2) AS cartao_credito,
    ROUND(100.0 * SUM(CASE WHEN i.tp_pagamento = 'debit_card' THEN i.pedidos_unicos ELSE 0 END) / t.total_pedidos, 2) AS cartao_debito,
    ROUND(100.0 * SUM(CASE WHEN i.tp_pagamento = 'vouncher' THEN i.pedidos_unicos ELSE 0 END) / t.total_pedidos, 2) AS vouncher,
    ROUND(100.0 * SUM(CASE WHEN i.tp_pagamento = 'not_defined' THEN i.pedidos_unicos ELSE 0 END) / t.total_pedidos, 2) AS not_defined
FROM info i
JOIN total_pedidos t
  ON i.mes_pedido = t.mes_pedido
GROUP BY i.mes_pedido, t.total_pedidos
ORDER BY i.mes_pedido;

-- COMMAND ----------

-- DBTITLE 1,3- MÉDIA DE QUANTIDADE DE PARCELAS
WITH info AS (
  SELECT
    pg.idPedido, 
    max(nrParcelas) as qtd_parcelas,
    date_trunc('month', pd.dtPedido) AS mes_pedido
  FROM silver.olist.pagamento_pedido AS pg
  LEFT JOIN silver.olist.pedido AS pd
    ON pd.idPedido = pg.idPedido
  WHERE pg.descTipoPagamento = 'credit_card'
  GROUP BY  mes_pedido , pg.idPedido
)
SELECT
  round(avg(qtd_parcelas), 2) AS avg_parcelas,
  mes_pedido
FROM info
GROUP BY mes_pedido


-- COMMAND ----------

-- MAGIC %md
-- MAGIC Dúvidas \
-- MAGIC 1- Só cartão de crédito possui mapgamento em parcelas? \
-- MAGIC 2- Como dentificar quando o pagamento é a vista?
