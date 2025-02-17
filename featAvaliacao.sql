WITH tb_base AS (
  SELECT distinct v.idVendedor, ip.idPedido, p.dtPedido, ap.idAvaliacao
  FROM silver.olist.vendedor as v
  LEFT JOIN silver.olist.item_pedido as ip ON v.idVendedor = ip.idVendedor
  LEFT JOIN silver.olist.pedido as p ON ip.idPedido = p.idPedido
  LEFT JOIN silver.olist.avaliacao_pedido as ap ON ip.idPedido = ap.idPedido
),
-- Criar a granularidade: Dtref (ANO/MÊS) + id.vendedor
tb_dtref_vendedor AS (
  SELECT DATE_TRUNC('MONTH', dtPedido) AS dtref, idVendedor, idPedido, idAvaliacao
  FROM tb_base
),
-- Incluir os atributos da feature store na tabela
tb_feat_avaliacao AS (
  SELECT dtref, idVendedor, 
         AVG(ap.vlNota) AS mediaAvaliacao,
         COUNT(ap.vlNota) AS qtdReviewsAteHoje,
         (COUNT(CASE WHEN dtv.idAvaliacao IS NULL THEN 1 END) * 1.0 / COUNT(dtv.idPedido)) * 100 AS pctPedidosNaoAvaliados -- pctPedidosNaoAvaliados = (qtd pedidos nao avaliados / qtd total de pedidos) * 100
  FROM tb_dtref_vendedor AS dtv
  LEFT JOIN silver.olist.avaliacao_pedido AS ap ON dtv.idAvaliacao = ap.idAvaliacao
  GROUP BY dtref, idVendedor
  ORDER BY pctPedidosNaoAvaliados DESC
)

SELECT *
FROM tb_feat_avaliacao