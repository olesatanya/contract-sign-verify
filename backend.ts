export const sign = async ( buyer: string, seller: string, tokenid: number, price: string, quantity: string, amount: string, timestamp: number ): Promise<string | null> => {
	try {
		const contract = new web3.eth.Contract( <any>abiStorefront, conf.storefront )
		const hash = await contract.methods.getMessageHash( buyer, seller, tokenid, price, quantity, amount, timestamp ).call()
		const { signature } = await web3.eth.accounts.sign(hash, privkey)
		return signature
	} catch (err:any) {
		setlog(err)
	}
	return null
}

export getParams = () => {
	const price = Math.round(priceETH * 1e18)
	const priceHex = toHex(price)
	const amount = toHex(price * count)
	const pidHex = toHex(pid)
	const msg = await setMyWallet(id, buyer)
	if (msg===null) {
		const signature = await sign( buyer, seller, tokenid, priceHex, quantity, amount, timestamp )
		if (signature) {
			return res.json({ status: 'ok', msg: [ pidHex, tokenid, priceHex, quantity, amount, timestamp, seller, signature ] })
		} else {
			return res.json({ status: 'err', msg: 'bad signature' })
		}
	} else {
		return res.json({ status: 'err', msg })
	}
}
