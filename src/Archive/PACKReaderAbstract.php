<?php
/**
 * Class PACKReaderAbstract
 *
 * @filesource   PACKReaderAbstract.php
 * @created      27.04.2019
 * @package      codemasher\WildstarDB\Archive
 * @author       smiley <smiley@chillerlan.net>
 * @copyright    2019 smiley
 * @license      MIT
 */

namespace codemasher\WildstarDB\Archive;

use chillerlan\Database\Database;
use codemasher\WildstarDB\WSDBException;

use function fread, fseek, unpack;

/**
 * @property array $blocktable
 */
abstract class PACKReaderAbstract extends ReaderAbstract{

	/**
	 * 4+4+512+8+8+8+4+4+4+8 = 564 bytes
	 *
	 * @var string
	 * @internal
	 */
	protected $FORMAT_HEADER = 'a4Signature/LVersion/x512/QFilesize/x8/QBlockTableOffset/LBlockCount/x4/LRootInfoIndex/x8';

	/**
	 * @var int
	 * @internal
	 */
	protected $headerSize = 564;

	/**
	 * @var array
	 */
	protected $blocktable = [];

	/**
	 * @return void
	 * @throws \codemasher\WildstarDB\WSDBException
	 */
	abstract protected function readData():void;

	/**
	 * @param string $filename
	 *
	 * @return \codemasher\WildstarDB\Archive\ReaderInterface
	 * @throws \codemasher\WildstarDB\WSDBException
	 */
	public function read(string $filename):ReaderInterface{
		$this->loadFile($filename);
		$this->blocktable = [];

		if($this->header['Signature'] !== "\x4b\x43\x41\x50"){ // KCAP
			throw new WSDBException('invalid PACK');
		}

		// read the block info table
		fseek($this->fh, $this->header['BlockTableOffset']);

		for($i = 0; $i < $this->header['BlockCount']; $i++){
			$this->blocktable[$i] = unpack('QOffset/QSize', fread($this->fh, 16));
		}

		// seek forward to the root index block for convenience
		fseek($this->fh, $this->blocktable[$this->header['RootInfoIndex']]['Offset']);

		$this->readData();

		return $this;
	}

	/**
	 * @param string|null $file
	 * @param string      $delimiter
	 * @param string      $enclosure
	 * @param string      $escapeChar
	 *
	 * @return string
	 * @throws \codemasher\WildstarDB\WSDBException
	 */
	public function toCSV(string $file = null, string $delimiter = ',', string $enclosure = '"', string $escapeChar = '\\'):string{
		// @todo
		throw new WSDBException('not implemented');

#		return '';
	}

	/**
	 * ugh!
	 *
	 * @param string|null $file
	 *
	 * @return string
	 * @throws \codemasher\WildstarDB\WSDBException
	 */
	public function toXML(string $file = null):string{
		// @todo
		throw new WSDBException('not implemented');

#		return '';
	}

	/**
	 * @param \chillerlan\Database\Database $db
	 *
	 * @return \codemasher\WildstarDB\Archive\ReaderInterface
	 * @throws \codemasher\WildstarDB\WSDBException
	 */
	public function toDB(Database $db):ReaderInterface{
		// @todo
		throw new WSDBException('not implemented');

#		return $this;
	}

}
