const res = await call('getParams', { action: 'buy', pid:args.id, count:status.quantity, buyer:wallet.address, buyPrice:price })
if (res.status === 'ok') {
    let result = null;
    const amount = price * status.quantity;
    if (status.token==='ETH') {
        hash = res.msg[4]
        result = await wallet.buy(res.msg, hash)
    } else {
        const approval = await wallet.approval(); 
        if (approval<amount) {
            result = await wallet.approve(amount);
            if (result.success && result.tx) {
                const tx = result.tx
                const success = await wallet.waitTransaction( tx.txid, AtLeast, (confirmations: number) => { setStatus({ ...status, loading: true, tx, txDesc:'Approve', confirmations }) } )
                if (!success) {
                    setError(success ? '' : '❌ transaction time out');
                    return setStatus({ ...status, loading: false, tx: null})
                }
            } else {
                setError('❌ transaction failed');
                return setStatus({ ...status, loading: false, tx: null})
            }
        }
        result = await wallet.buy(res.msg, 0)
    }
    if (result.success && result.tx) {
        const tx = result.tx
        await call('/api/artwork/' + art.id, { action: 'tx', tx })
        setStatus({ ...status, loading: true, tx })
        const success = await wallet.waitTransaction( tx.txid, AtLeast, (confirmations: number) => { setStatus({ ...status, loading: true, tx, txDesc:'Buying', confirmations }) } )
        setError(success ? '' : '❌ transaction time out')
        await call('/api/artwork/' + art.id, { action: 'check' })
        return window.open('/my/purchased', '_self')
    } else {
        err = result.errmsg || ''
    }
} else {
    err = 'An unexpected error occurred while getting data from the server.'
}