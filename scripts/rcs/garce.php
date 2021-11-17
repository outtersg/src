<?php
/*
 * Copyright (c) 2021 Guillaume Outters
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/* NOTE: besoin
 * Ce gros crétin de git détermine que la base de fusion est "le plus récent contenu par les deux côtés".
 * Ce qui fait que si la branche A provient du commit 5 (uniquement) tandis que B provient d'une fusion de 5 et de 1 qui eux-mêmes proviennent tous deux de 0, pour git, le 5 répond aux critères et est donc remonté comme point de départ au lieu de 0.
 * Cf. https://stackoverflow.com/a/51526818
 */

/**
 * Git Ancêtre Réellement Commun par Exploration
 */
class Garce
{
	public function racine($branches)
	{
		$manques = $this->_ras($branches);
		while(count($manques) > 1)
			$manques = $this->_manques($manques);
		
		echo array_shift($manques);
	}
	
	/**
	 * Renvoie chaque réf sous forme de son SHA.
	 */
	protected function _ras($réfs)
	{
		foreach($réfs as & $ptrRéf)
		{
			unset($pousses);
			exec("git log -n 1 --pretty=format:'%H' $ptrRéf", /*&*/ $pousses, /*&*/ $r);
			if($r) throw new Exception('git log -n 1 sorti en erreur '.$r);
			$ptrRéf = $pousses[0];
		}
		return $réfs;
	}
	
	protected function _manques($réfs)
	{
		$manques = [];
		$arbo = $this->_paquet($réfs, /*&*/ $racines);
		foreach($arbo + $racines as $fil => $parents)
			foreach($parents as $parent)
			if(!isset($arbo[$parent]) || $arbo[$parent] === true)
				$manques[$parent] = true;
		return array_keys($manques);
	}
	
	protected function _paquet($réfs, & $racines)
	{
		$retour = [];
		$racines = [];
		
		exec('git show-branch --merge-base '.implode(' ', $réfs), /*&*/ $ancêtres, /*&*/ $r);
		if($r) throw new Exception('git branch --merge-base sorti en erreur '.$r);
		
		foreach($ancêtres as $a)
		{
			// Cas particulier:
			// pour git, A..B signifie ]A;B] et non [A;B]
			// A..A renverra donc l'ensemble vide.
			// Fonctionnellement, pour nous cela veut dire:
			// - s'il s'agit du seul résultat, tout le monde converge vers lui: c'est notre résultat unique.
			// - si in fine on découvre un autre parent à rechercher, les deux reviennent en lice sur pied d'égalité.
			if(in_array($a, $réfs))
				$racines = [ $a => [ $a ] ];
			foreach($réfs as $réf)
			{
				exec("git log --pretty=format:'%H %P' $a..$réf", /*&*/ $pousses, /*&*/ $r);
				if($r) throw new Exception('git log sorti en erreur '.$r);
				foreach($pousses as $parents)
				{
					$parents = explode(' ', $parents);
					$fil = array_shift($parents);
					$retour[$fil] = $parents;
				}
			}
		}
		return $retour;
	}
}

$g = new Garce();
array_shift($argv);
$g->racine($argv);

?>
